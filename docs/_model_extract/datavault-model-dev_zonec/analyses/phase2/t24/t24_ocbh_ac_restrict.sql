-- Source: .t24.t24_ocbh_ac_restrict
-- Target: :catalog_cleaned.raw_vault
--   hub_account, sts_hub_account_ac_restrict, sat_ac_restrict
-- Phase2 addition: priority 2 source.
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_ocbh_ac_restrict; CREATE TEMPORARY TABLE tmp_t24_ocbh_ac_restrict AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS account_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_customer AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ac_title AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_category AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_currency AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ac_restrict AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_res_customer AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_res_ac_title AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_res_category AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_res_currency AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), ''), 256) AS hd_ac_restrict,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_customer, t_ac_title, t_category, t_currency, t_ac_restrict,
    t_res_customer, t_res_ac_title, t_res_category, t_res_currency,
    t_inputter, t_authoriser, t_date_time, t_co_code
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_ocbh_ac_restrict')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_account] Moved to t24_accr_acct_cr.sql (consolidated UNION ALL to avoid Delta version conflicts)
-- [sts_hub_account_ac_restrict] Moved to t24_accr_acct_cr.sql (hub_account must exist before computing sts)

-- [sat_ac_restrict] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_ac_restrict')
(account_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_customer, t_ac_title, t_category, t_currency, t_ac_restrict,
 t_res_customer, t_res_ac_title, t_res_category, t_res_currency,
 t_inputter, t_authoriser, t_date_time, t_co_code)
WITH last_known AS (
    SELECT account_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_ac_restrict')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_ac_restrict) OVER (PARTITION BY s.account_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_ocbh_ac_restrict s
    LEFT JOIN last_known lk ON lk.account_hashkey = s.account_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_ac_restrict != prev_hashdiff)
SELECT d.account_hashkey, d.hd_ac_restrict, d.source_event_date, current_timestamp(), 't24__t24_ocbh_ac_restrict',
       d.t_customer, d.t_ac_title, d.t_category, d.t_currency, d.t_ac_restrict,
       d.t_res_customer, d.t_res_ac_title, d.t_res_category, d.t_res_currency,
       d.t_inputter, d.t_authoriser, d.t_date_time, d.t_co_code
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_ac_restrict') t ON t.account_hashkey = d.account_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_ocbh_ac_restrict;
