-- Source: .t24.t24_stmt_acct_cr
-- Target: :catalog_cleaned.raw_vault
--   hub_account, sts_hub_account_stmt_acct_cr, sat_stmt_acct_cr, sat_stmt_acct_cr_other
-- Phase2 addition: priority 2 source. business_key = split_part(id,'-',1), ma_key = trim(split_part(id,'-',2))
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_stmt_acct_cr; CREATE TEMPORARY TABLE tmp_t24_stmt_acct_cr AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(split_part(id, '-', 1) AS string))), ''), 256) AS account_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(trim(split_part(id, '-', 2)) AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_liquidity_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_period_first_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_period_last_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_no_of_days AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_categ AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_val_balance AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_tr_ac AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_tr_pl AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_liquidity_account AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_compens_account AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_int_no_booking AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_total_interest AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_grand_total AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_min_value AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_min_waive AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_unadj_total_int AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_int_post_date AS string))), ''), 256) AS hd_stmt_acct_cr,
    sha2(COALESCE(UPPER(TRIM(CAST(trim(split_part(id, '-', 2)) AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_tax_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_tax_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_tax_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_taxcateg AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_taxtrsdr AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_taxtrscr AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_tax_for_customer AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_tax_for_bank AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_int_categ AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_tr_ac AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_tr_pl AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_main_int AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_sub_int AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_post_interest AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_main_acct AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_dist_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_dist_ratio AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_tax_exch_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_manual_adj_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_correction_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_correction_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_adj_int_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_adj_tax_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_withheld_int_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_db_netting_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_correction_date AS string))), ''), 256) AS hd_stmt_acct_cr_other,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    trim(split_part(id, '-', 1)) AS account_bk,
    trim(split_part(id, '-', 2)) AS ma_key,
    t_liquidity_ccy, t_period_first_date, t_period_last_date, t_cr_int_rate, t_cr_int_date,
    t_cr_no_of_days, t_cr_int_amt, t_cr_int_categ, t_cr_val_balance, t_cr_int_tr_ac, t_cr_int_tr_pl,
    t_liquidity_account, t_compens_account, t_int_no_booking, t_total_interest, t_grand_total,
    t_cr_min_value, t_cr_min_waive, t_unadj_total_int, t_int_post_date,
    t_cr_int_tax_code, t_cr_int_tax_rate, t_cr_int_tax_amt, t_cr_int_taxcateg, t_cr_int_taxtrsdr, t_cr_int_taxtrscr,
    t_tax_for_customer, t_tax_for_bank, t_ica_int_categ, t_ica_tr_ac, t_ica_tr_pl, t_ica_main_int, t_ica_sub_int,
    t_ica_post_interest, t_ica_main_acct, t_ica_dist_type, t_ica_dist_ratio, t_tax_exch_rate, t_manual_adj_amt,
    t_correction_number, t_correction_id, t_adj_int_amt, t_adj_tax_amt, t_withheld_int_amt, t_db_netting_amt, t_correction_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_stmt_acct_cr')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_account] Moved to t24_accr_acct_cr.sql (consolidated UNION ALL to avoid Delta version conflicts)
-- [sts_hub_account_stmt_acct_cr] Moved to t24_accr_acct_cr.sql (hub_account must exist before computing sts)

-- [sat_stmt_acct_cr] Multi-value satellite — compare with latest per (account_hashkey, ma_key)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_stmt_acct_cr')
(account_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, t_liquidity_ccy, t_period_first_date, t_period_last_date, t_cr_int_rate, t_cr_int_date,
 t_cr_no_of_days, t_cr_int_amt, t_cr_int_categ, t_cr_val_balance, t_cr_int_tr_ac, t_cr_int_tr_pl,
 t_liquidity_account, t_compens_account, t_int_no_booking, t_total_interest, t_grand_total,
 t_cr_min_value, t_cr_min_waive, t_unadj_total_int, t_int_post_date)
WITH last_known AS (
    SELECT account_hashkey, ma_key, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_stmt_acct_cr')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey, ma_key ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_stmt_acct_cr) OVER (PARTITION BY s.account_hashkey, s.ma_key ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_stmt_acct_cr s
    LEFT JOIN last_known lk ON lk.account_hashkey = s.account_hashkey AND lk.ma_key = s.ma_key
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_stmt_acct_cr != prev_hashdiff)
SELECT d.account_hashkey, d.hd_stmt_acct_cr, d.source_event_date, current_timestamp(), 't24__t24_stmt_acct_cr',
       d.ma_key, d.t_liquidity_ccy, d.t_period_first_date, d.t_period_last_date, d.t_cr_int_rate, d.t_cr_int_date,
       d.t_cr_no_of_days, d.t_cr_int_amt, d.t_cr_int_categ, d.t_cr_val_balance, d.t_cr_int_tr_ac, d.t_cr_int_tr_pl,
       d.t_liquidity_account, d.t_compens_account, d.t_int_no_booking, d.t_total_interest, d.t_grand_total,
       d.t_cr_min_value, d.t_cr_min_waive, d.t_unadj_total_int, d.t_int_post_date
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_stmt_acct_cr') t ON t.account_hashkey = d.account_hashkey AND t.ma_key = d.ma_key AND t.source_event_date = d.source_event_date;

-- [sat_stmt_acct_cr_other] Multi-value satellite — compare with latest per (account_hashkey, ma_key)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_stmt_acct_cr_other')
(account_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, t_cr_int_tax_code, t_cr_int_tax_rate, t_cr_int_tax_amt, t_cr_int_taxcateg, t_cr_int_taxtrsdr, t_cr_int_taxtrscr,
 t_tax_for_customer, t_tax_for_bank, t_ica_int_categ, t_ica_tr_ac, t_ica_tr_pl, t_ica_main_int, t_ica_sub_int,
 t_ica_post_interest, t_ica_main_acct, t_ica_dist_type, t_ica_dist_ratio, t_tax_exch_rate, t_manual_adj_amt,
 t_correction_number, t_correction_id, t_adj_int_amt, t_adj_tax_amt, t_withheld_int_amt, t_db_netting_amt, t_correction_date)
WITH last_known AS (
    SELECT account_hashkey, ma_key, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_stmt_acct_cr_other')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey, ma_key ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_stmt_acct_cr_other) OVER (PARTITION BY s.account_hashkey, s.ma_key ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_stmt_acct_cr s
    LEFT JOIN last_known lk ON lk.account_hashkey = s.account_hashkey AND lk.ma_key = s.ma_key
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_stmt_acct_cr_other != prev_hashdiff)
SELECT d.account_hashkey, d.hd_stmt_acct_cr_other, d.source_event_date, current_timestamp(), 't24__t24_stmt_acct_cr',
       d.ma_key, d.t_cr_int_tax_code, d.t_cr_int_tax_rate, d.t_cr_int_tax_amt, d.t_cr_int_taxcateg, d.t_cr_int_taxtrsdr, d.t_cr_int_taxtrscr,
       d.t_tax_for_customer, d.t_tax_for_bank, d.t_ica_int_categ, d.t_ica_tr_ac, d.t_ica_tr_pl, d.t_ica_main_int, d.t_ica_sub_int,
       d.t_ica_post_interest, d.t_ica_main_acct, d.t_ica_dist_type, d.t_ica_dist_ratio, d.t_tax_exch_rate, d.t_manual_adj_amt,
       d.t_correction_number, d.t_correction_id, d.t_adj_int_amt, d.t_adj_tax_amt, d.t_withheld_int_amt, d.t_db_netting_amt, d.t_correction_date
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_stmt_acct_cr_other') t ON t.account_hashkey = d.account_hashkey AND t.ma_key = d.ma_key AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_stmt_acct_cr;
