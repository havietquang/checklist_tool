-- Source: .t24.t24_user_level_auth
-- Target: :catalog_cleaned.raw_vault
--   hub_user, sts_hub_user_level_auth, sat_user_level_auth
-- Phase2 addition: priority 2 source.
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_user_level_auth; CREATE TEMPORARY TABLE tmp_t24_user_level_auth AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS user_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_auth_level_default AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_auth_level_short_term AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_begin_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_expire_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_value_date AS string))), ''), 256) AS hd_user_level_auth,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_co_code, t_auth_level_default, t_auth_level_short_term, t_begin_date, t_expire_date, t_value_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_user_level_auth')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_vmbh_teller_limit_s; CREATE TEMPORARY TABLE tmp_t24_vmbh_teller_limit_s AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS user_hashkey,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_vmbh_teller_limit')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_user] Consolidated insert from t24_user_level_auth and t24_vmbh_teller_limit sources to avoid Delta version conflicts
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_user')
(user_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH all_sources AS (
    SELECT user_hashkey, CAST(id AS STRING) AS business_key, source_event_date, 't24__t24_user_level_auth' AS record_source, data_date, 2 AS source_priority
    FROM tmp_t24_user_level_auth
    UNION ALL
    SELECT user_hashkey, CAST(id AS STRING), source_event_date, 't24__t24_vmbh_teller_limit', data_date, 2
    FROM tmp_t24_vmbh_teller_limit_s
),
deduped AS (SELECT * FROM all_sources QUALIFY ROW_NUMBER() OVER (PARTITION BY user_hashkey ORDER BY data_date, source_priority) = 1)
SELECT d.user_hashkey, d.business_key, d.source_event_date, current_timestamp(), d.record_source
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_user') t
    ON t.user_hashkey = d.user_hashkey;

-- [sts_hub_user_level_auth] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_user_level_auth')
(user_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_user_level_auth
),
present_per_date AS (
    SELECT DISTINCT user_hashkey, source_event_date FROM tmp_t24_user_level_auth
),
full_timeline AS (
    SELECT DISTINCT h.user_hashkey, d.source_event_date,
           CASE WHEN p.user_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_user') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.user_hashkey = h.user_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT user_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY user_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT user_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_user_level_auth')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_user_level_auth)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY user_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.user_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.user_hashkey = t.user_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.user_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.user_hashkey = t.user_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.user_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_user_level_auth') t
    ON t.user_hashkey = sc.user_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sts_hub_user_teller_limit] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_user_teller_limit')
(user_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_vmbh_teller_limit_s
),
present_per_date AS (
    SELECT DISTINCT user_hashkey, source_event_date FROM tmp_t24_vmbh_teller_limit_s
),
full_timeline AS (
    SELECT DISTINCT h.user_hashkey, d.source_event_date,
           CASE WHEN p.user_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_user') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.user_hashkey = h.user_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT user_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY user_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT user_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_user_teller_limit')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_vmbh_teller_limit_s)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY user_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.user_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.user_hashkey = t.user_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.user_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.user_hashkey = t.user_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.user_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_user_teller_limit') t
    ON t.user_hashkey = sc.user_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_user_level_auth] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_user_level_auth')
(user_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_co_code, t_auth_level_default, t_auth_level_short_term, t_begin_date, t_expire_date, t_value_date)
WITH last_known AS (
    SELECT user_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_user_level_auth')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY user_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_user_level_auth) OVER (PARTITION BY s.user_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_user_level_auth s
    LEFT JOIN last_known lk ON lk.user_hashkey = s.user_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_user_level_auth != prev_hashdiff)
SELECT d.user_hashkey, d.hd_user_level_auth, d.source_event_date, current_timestamp(), 't24__t24_user_level_auth',
       d.t_co_code, d.t_auth_level_default, d.t_auth_level_short_term, d.t_begin_date, d.t_expire_date, d.t_value_date
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_user_level_auth') t ON t.user_hashkey = d.user_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_user_level_auth;
DROP TEMPORARY TABLE IF EXISTS tmp_t24_vmbh_teller_limit_s;
