-- Source: .t24.t24_apportion_acct_categ
-- Target: :catalog_cleaned.raw_vault
--   hub_apportion_acct_categ, sts_hub_apportion_acct_categ, sat_apportion_acct_categ
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_apportion_acct_categ; CREATE TEMPORARY TABLE tmp_t24_apportion_acct_categ AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS apportion_acct_categ_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_parent_account AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_level3 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_line AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_account_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_categ_internal AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cust_group AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_categ_pl AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_type_business AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_is_mand AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_categ_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_from_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pbnb AS string))), ''), 256) AS hd_apportion_acct_categ,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_parent_account, t_level3, t_line, t_account_name, t_categ_internal, t_cust_group, t_no,
    t_categ_pl, t_type_business, t_is_mand, t_categ_type, t_from_date, t_status, t_pbnb
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_apportion_acct_categ')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_apportion_acct_categ] Insert business keys not yet in hub (ANTI JOIN on hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_apportion_acct_categ')
(apportion_acct_categ_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_apportion_acct_categ QUALIFY ROW_NUMBER() OVER (PARTITION BY apportion_acct_categ_hashkey ORDER BY data_date) = 1)
SELECT d.apportion_acct_categ_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 't24__t24_apportion_acct_categ'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_apportion_acct_categ') t
    ON t.apportion_acct_categ_hashkey = d.apportion_acct_categ_hashkey;

-- [sts_hub_apportion_acct_categ] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_apportion_acct_categ')
(apportion_acct_categ_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_apportion_acct_categ
),
present_per_date AS (
    SELECT DISTINCT apportion_acct_categ_hashkey, source_event_date FROM tmp_t24_apportion_acct_categ
),
full_timeline AS (
    SELECT DISTINCT h.apportion_acct_categ_hashkey, d.source_event_date,
           CASE WHEN p.apportion_acct_categ_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_apportion_acct_categ') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.apportion_acct_categ_hashkey = h.apportion_acct_categ_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT apportion_acct_categ_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY apportion_acct_categ_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT apportion_acct_categ_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_apportion_acct_categ')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_apportion_acct_categ)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY apportion_acct_categ_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.apportion_acct_categ_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.apportion_acct_categ_hashkey = t.apportion_acct_categ_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.apportion_acct_categ_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.apportion_acct_categ_hashkey = t.apportion_acct_categ_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.apportion_acct_categ_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_apportion_acct_categ') t
    ON t.apportion_acct_categ_hashkey = sc.apportion_acct_categ_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_apportion_acct_categ] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_apportion_acct_categ')
(apportion_acct_categ_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_parent_account, t_level3, t_line, t_account_name, t_categ_internal, t_cust_group, t_no,
 t_categ_pl, t_type_business, t_is_mand, t_categ_type, t_from_date, t_status, t_pbnb)
WITH last_known AS (
    SELECT apportion_acct_categ_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_apportion_acct_categ')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY apportion_acct_categ_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_apportion_acct_categ) OVER (PARTITION BY s.apportion_acct_categ_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_apportion_acct_categ s
    LEFT JOIN last_known lk ON lk.apportion_acct_categ_hashkey = s.apportion_acct_categ_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_apportion_acct_categ != prev_hashdiff)
SELECT d.apportion_acct_categ_hashkey, d.hd_apportion_acct_categ, d.source_event_date, current_timestamp(), 't24__t24_apportion_acct_categ',
       d.t_parent_account, d.t_level3, d.t_line, d.t_account_name, d.t_categ_internal, d.t_cust_group, d.t_no,
       d.t_categ_pl, d.t_type_business, d.t_is_mand, d.t_categ_type, d.t_from_date, d.t_status, d.t_pbnb
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_apportion_acct_categ') t ON t.apportion_acct_categ_hashkey = d.apportion_acct_categ_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_apportion_acct_categ;
