-- Source: .t24.t24_acct_activity
-- Target: :catalog_cleaned.raw_vault
--   hub_account, sts_hub_account_acct_activity, sat_acct_activity
-- Phase2 addition: priority 2 source. business_key = split_part(id,'-',1), ma_key = trim(split_part(id,'-',2))
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_acct_activity; CREATE TEMPORARY TABLE tmp_t24_acct_activity AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(split_part(id, '-', 1) AS string))), ''), 256) AS account_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(trim(split_part(id, '-', 2)) AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_day_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_turnover_credit AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_turnover_debit AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_balance AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_transact_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_no_of_transact AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_transact_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_bk_day_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_bk_balance AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_bk_credit_mvmt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_bk_debit_mvmt AS string))), ''), 256) AS hd_acct_activity,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    trim(split_part(id, '-', 1)) AS account_bk,
    trim(split_part(id, '-', 2)) AS ma_key,
    t_day_no, t_turnover_credit, t_turnover_debit, t_balance, t_transact_code,
    t_no_of_transact, t_transact_amt, t_bk_day_no, t_bk_balance, t_bk_credit_mvmt, t_bk_debit_mvmt
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_acct_activity')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_account] Moved to t24_accr_acct_cr.sql (consolidated UNION ALL to avoid Delta version conflicts)
-- [sts_hub_account_acct_activity] Moved to t24_accr_acct_cr.sql (hub_account must exist before computing sts)

-- [sat_acct_activity] Multi-value satellite — compare with latest per (account_hashkey, ma_key)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_acct_activity')
(account_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, t_day_no, t_turnover_credit, t_turnover_debit, t_balance, t_transact_code,
 t_no_of_transact, t_transact_amt, t_bk_day_no, t_bk_balance, t_bk_credit_mvmt, t_bk_debit_mvmt)
WITH last_known AS (
    SELECT account_hashkey, ma_key, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_acct_activity')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey, ma_key ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_acct_activity) OVER (PARTITION BY s.account_hashkey, s.ma_key ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_acct_activity s
    LEFT JOIN last_known lk ON lk.account_hashkey = s.account_hashkey AND lk.ma_key = s.ma_key
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_acct_activity != prev_hashdiff)
SELECT d.account_hashkey, d.hd_acct_activity, d.source_event_date, current_timestamp(), 't24__t24_acct_activity',
       d.ma_key, d.t_day_no, d.t_turnover_credit, d.t_turnover_debit, d.t_balance, d.t_transact_code,
       d.t_no_of_transact, d.t_transact_amt, d.t_bk_day_no, d.t_bk_balance, d.t_bk_credit_mvmt, d.t_bk_debit_mvmt
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_acct_activity') t ON t.account_hashkey = d.account_hashkey AND t.ma_key = d.ma_key AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_acct_activity;
