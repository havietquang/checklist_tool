-- Source: .t24.t24_periodic_interest
-- Target: :catalog_cleaned.raw_vault
--   hub_periodic_interest, sts_hub_periodic_interest, sat_periodic_interest
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_periodic_interest; CREATE TEMPORARY TABLE tmp_t24_periodic_interest AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS periodic_interest_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_default_mis_table AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rest_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_days_since_spot AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_bid_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_offer_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rest_period AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), ''), 256) AS hd_periodic_interest,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_description, t_default_mis_table, t_rest_date, t_days_since_spot, t_bid_rate, t_offer_rate,
    t_rest_period, t_record_status, t_curr_no, t_inputter, t_authoriser, t_date_time, t_co_code
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_periodic_interest')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_periodic_interest] Insert business keys not yet in hub (ANTI JOIN on hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_periodic_interest')
(periodic_interest_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_periodic_interest QUALIFY ROW_NUMBER() OVER (PARTITION BY periodic_interest_hashkey ORDER BY data_date) = 1)
SELECT d.periodic_interest_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 't24__t24_periodic_interest'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_periodic_interest') t
    ON t.periodic_interest_hashkey = d.periodic_interest_hashkey;

-- [sts_hub_periodic_interest] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_periodic_interest')
(periodic_interest_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_periodic_interest
),
present_per_date AS (
    SELECT DISTINCT periodic_interest_hashkey, source_event_date FROM tmp_t24_periodic_interest
),
full_timeline AS (
    SELECT DISTINCT h.periodic_interest_hashkey, d.source_event_date,
           CASE WHEN p.periodic_interest_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_periodic_interest') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.periodic_interest_hashkey = h.periodic_interest_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT periodic_interest_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY periodic_interest_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT periodic_interest_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_periodic_interest')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_periodic_interest)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY periodic_interest_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.periodic_interest_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.periodic_interest_hashkey = t.periodic_interest_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.periodic_interest_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.periodic_interest_hashkey = t.periodic_interest_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.periodic_interest_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_periodic_interest') t
    ON t.periodic_interest_hashkey = sc.periodic_interest_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_periodic_interest] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_periodic_interest')
(periodic_interest_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_description, t_default_mis_table, t_rest_date, t_days_since_spot, t_bid_rate, t_offer_rate,
 t_rest_period, t_record_status, t_curr_no, t_inputter, t_authoriser, t_date_time, t_co_code)
WITH last_known AS (
    SELECT periodic_interest_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_periodic_interest')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY periodic_interest_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_periodic_interest) OVER (PARTITION BY s.periodic_interest_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_periodic_interest s
    LEFT JOIN last_known lk ON lk.periodic_interest_hashkey = s.periodic_interest_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_periodic_interest != prev_hashdiff)
SELECT d.periodic_interest_hashkey, d.hd_periodic_interest, d.source_event_date, current_timestamp(), 't24__t24_periodic_interest',
       d.t_description, d.t_default_mis_table, d.t_rest_date, d.t_days_since_spot, d.t_bid_rate, d.t_offer_rate,
       d.t_rest_period, d.t_record_status, d.t_curr_no, d.t_inputter, d.t_authoriser, d.t_date_time, d.t_co_code
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_periodic_interest') t ON t.periodic_interest_hashkey = d.periodic_interest_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_periodic_interest;
