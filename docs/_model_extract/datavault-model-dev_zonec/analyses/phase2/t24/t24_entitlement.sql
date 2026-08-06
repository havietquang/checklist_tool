-- Source: .t24.t24_entitlement
-- Target: :catalog_cleaned.raw_vault
--   hub_diary, sts_hub_diary_entitlement, sat_entitlement
-- Phase2 addition: priority 2 source for hub_diary. business_key = split_part(id,'-',1), ma_key = trim(split_part(id,'-',2))
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_entitlement; CREATE TEMPORARY TABLE tmp_t24_entitlement AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(split_part(id, '-', 1) AS string))), ''), 256) AS diary_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(trim(split_part(id, '-', 2)) AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_portfolio_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_security_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_entitlement_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_event_type AS string))), ''), 256) AS hd_entitlement,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    trim(split_part(id, '-', 1)) AS diary_bk,
    trim(split_part(id, '-', 2)) AS ma_key,
    t_portfolio_no, t_security_no, t_record_status, t_entitlement_amt, t_event_type
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_entitlement')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [sat_entitlement] Multi-value satellite — compare with latest per (diary_hashkey, ma_key)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_entitlement')
(diary_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, t_portfolio_no, t_security_no, t_record_status, t_entitlement_amt, t_event_type)
WITH last_known AS (
    SELECT diary_hashkey, ma_key, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_entitlement')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY diary_hashkey, ma_key ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_entitlement) OVER (PARTITION BY s.diary_hashkey, s.ma_key ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_entitlement s
    LEFT JOIN last_known lk ON lk.diary_hashkey = s.diary_hashkey AND lk.ma_key = s.ma_key
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_entitlement != prev_hashdiff)
SELECT d.diary_hashkey, d.hd_entitlement, d.source_event_date, current_timestamp(), 't24__t24_entitlement',
       d.ma_key, d.t_portfolio_no, d.t_security_no, d.t_record_status, d.t_entitlement_amt, d.t_event_type
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_entitlement') t ON t.diary_hashkey = d.diary_hashkey AND t.ma_key = d.ma_key AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_entitlement;
