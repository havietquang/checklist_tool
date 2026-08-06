-- Source: .t24.t24_vmbh_teller_limit
-- Target: :catalog_cleaned.raw_vault
--   hub_user, sts_hub_user_teller_limit, sat_teller_limit
-- Phase2 addition: priority 2 source.
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_vmbh_teller_limit; CREATE TEMPORARY TABLE tmp_t24_vmbh_teller_limit AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS user_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_txn_cod AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_limit_amount AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_curr_mo AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), ''), 256) AS hd_teller_limit,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_ccy, t_txn_cod, t_limit_amount, t_co_code, t_date_time, t_curr_mo, t_inputter, t_authoriser
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_vmbh_teller_limit')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_user] Moved to t24_user_level_auth.sql (consolidated UNION ALL to avoid Delta version conflicts)
-- [sts_hub_user_teller_limit] Moved to t24_user_level_auth.sql (hub_user must exist before computing sts)

-- [sat_teller_limit] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_teller_limit')
(user_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_ccy, t_txn_cod, t_limit_amount, t_co_code, t_date_time, t_curr_mo, t_inputter, t_authoriser)
WITH last_known AS (
    SELECT user_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_teller_limit')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY user_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_teller_limit) OVER (PARTITION BY s.user_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_vmbh_teller_limit s
    LEFT JOIN last_known lk ON lk.user_hashkey = s.user_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_teller_limit != prev_hashdiff)
SELECT d.user_hashkey, d.hd_teller_limit, d.source_event_date, current_timestamp(), 't24__t24_vmbh_teller_limit',
       d.t_ccy, d.t_txn_cod, d.t_limit_amount, d.t_co_code, d.t_date_time, d.t_curr_mo, d.t_inputter, d.t_authoriser
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_teller_limit') t ON t.user_hashkey = d.user_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_vmbh_teller_limit;
