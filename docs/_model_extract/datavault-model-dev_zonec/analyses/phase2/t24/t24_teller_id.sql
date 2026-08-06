-- Source: .t24.t24_teller_id
-- Target: :catalog_cleaned.raw_vault
--   hub_teller_id, sts_hub_teller_id, sat_teller_id
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_teller_id; CREATE TEMPORARY TABLE tmp_t24_teller_id AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS teller_id_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_user AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_of_open AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_time_of_open AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_of_close AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_time_of_close AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_dept_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_till_limit AS string))), ''), 256) AS hd_teller_id,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_status, t_user, t_date_of_open, t_time_of_open, t_date_of_close, t_time_of_close,
    t_curr_no, t_inputter, t_date_time, t_authoriser, t_co_code, t_dept_code, t_till_limit
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_teller_id')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_teller_id] Insert business keys not yet in hub (ANTI JOIN on hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_teller_id')
(teller_id_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_teller_id QUALIFY ROW_NUMBER() OVER (PARTITION BY teller_id_hashkey ORDER BY data_date) = 1)
SELECT d.teller_id_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 't24__t24_teller_id'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_teller_id') t
    ON t.teller_id_hashkey = d.teller_id_hashkey;

-- [sts_hub_teller_id] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_teller_id')
(teller_id_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_teller_id
),
present_per_date AS (
    SELECT DISTINCT teller_id_hashkey, source_event_date FROM tmp_t24_teller_id
),
full_timeline AS (
    SELECT DISTINCT h.teller_id_hashkey, d.source_event_date,
           CASE WHEN p.teller_id_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_teller_id') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.teller_id_hashkey = h.teller_id_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT teller_id_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY teller_id_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT teller_id_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_teller_id')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_teller_id)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY teller_id_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.teller_id_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.teller_id_hashkey = t.teller_id_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.teller_id_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.teller_id_hashkey = t.teller_id_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.teller_id_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_teller_id') t
    ON t.teller_id_hashkey = sc.teller_id_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_teller_id] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_teller_id')
(teller_id_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_status, t_user, t_date_of_open, t_time_of_open, t_date_of_close, t_time_of_close,
 t_curr_no, t_inputter, t_date_time, t_authoriser, t_co_code, t_dept_code, t_till_limit)
WITH last_known AS (
    SELECT teller_id_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_teller_id')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY teller_id_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_teller_id) OVER (PARTITION BY s.teller_id_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_teller_id s
    LEFT JOIN last_known lk ON lk.teller_id_hashkey = s.teller_id_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_teller_id != prev_hashdiff)
SELECT d.teller_id_hashkey, d.hd_teller_id, d.source_event_date, current_timestamp(), 't24__t24_teller_id',
       d.t_status, d.t_user, d.t_date_of_open, d.t_time_of_open, d.t_date_of_close, d.t_time_of_close,
       d.t_curr_no, d.t_inputter, d.t_date_time, d.t_authoriser, d.t_co_code, d.t_dept_code, d.t_till_limit
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_teller_id') t ON t.teller_id_hashkey = d.teller_id_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_teller_id;
