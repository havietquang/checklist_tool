-- Source: .t24.t24_stmt_acct_dr
-- Target: :catalog_cleaned.raw_vault
--   hub_account, sts_hub_account_stmt_acct_dr, sat_stmt_acct_dr
-- Phase2 addition: priority 2 source. business_key = split_part(id,'-',1), ma_key = trim(split_part(id,'-',2))
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_stmt_acct_dr; CREATE TEMPORARY TABLE tmp_t24_stmt_acct_dr AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(split_part(id, '-', 1) AS string))), ''), 256) AS account_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(trim(split_part(id, '-', 2)) AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_liquidity_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_period_first_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_period_last_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_dr_int_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_dr_int_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_dr_no_of_days AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_dr_int_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_dr_int_categ AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_dr_val_balance AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_dr_int_tr_ac AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_dr_int_tr_pl AS string))), ''), 256) AS hd_stmt_acct_dr,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    trim(split_part(id, '-', 1)) AS account_bk,
    trim(split_part(id, '-', 2)) AS ma_key,
    t_liquidity_ccy, t_period_first_date, t_period_last_date, t_dr_int_rate, t_dr_int_date,
    t_dr_no_of_days, t_dr_int_amt, t_dr_int_categ, t_dr_val_balance, t_dr_int_tr_ac, t_dr_int_tr_pl
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_stmt_acct_dr')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_account] Moved to t24_accr_acct_cr.sql (consolidated UNION ALL to avoid Delta version conflicts)
-- [sts_hub_account_stmt_acct_dr] Moved to t24_accr_acct_cr.sql (hub_account must exist before computing sts)

-- [sat_stmt_acct_dr] Multi-value satellite — compare with latest per (account_hashkey, ma_key)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_stmt_acct_dr')
(account_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, t_liquidity_ccy, t_period_first_date, t_period_last_date, t_dr_int_rate, t_dr_int_date,
 t_dr_no_of_days, t_dr_int_amt, t_dr_int_categ, t_dr_val_balance, t_dr_int_tr_ac, t_dr_int_tr_pl)
WITH last_known AS (
    SELECT account_hashkey, ma_key, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_stmt_acct_dr')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey, ma_key ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_stmt_acct_dr) OVER (PARTITION BY s.account_hashkey, s.ma_key ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_stmt_acct_dr s
    LEFT JOIN last_known lk ON lk.account_hashkey = s.account_hashkey AND lk.ma_key = s.ma_key
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_stmt_acct_dr != prev_hashdiff)
SELECT d.account_hashkey, d.hd_stmt_acct_dr, d.source_event_date, current_timestamp(), 't24__t24_stmt_acct_dr',
       d.ma_key, d.t_liquidity_ccy, d.t_period_first_date, d.t_period_last_date, d.t_dr_int_rate, d.t_dr_int_date,
       d.t_dr_no_of_days, d.t_dr_int_amt, d.t_dr_int_categ, d.t_dr_val_balance, d.t_dr_int_tr_ac, d.t_dr_int_tr_pl
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_stmt_acct_dr') t ON t.account_hashkey = d.account_hashkey AND t.ma_key = d.ma_key AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_stmt_acct_dr;
