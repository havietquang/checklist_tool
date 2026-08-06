-- Source: .t24.t24_accr_acct_cr
-- Target: :catalog_cleaned.raw_vault
--   hub_account, sts_hub_account_accr_acct_cr,
--   sat_accr_acct_cr_dynamic, sat_accr_acct_cr_information, sat_accr_acct_cr_other
-- Phase2 addition: priority 2 source.
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_accr_acct_cr; CREATE TEMPORARY TABLE tmp_t24_accr_acct_cr AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS account_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_period_last_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_int_post_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_no_of_days AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_total_interest AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_grand_total AS string))), ''), 256) AS hd_accr_acct_cr_dynamic,
    sha2(COALESCE(UPPER(TRIM(CAST(t_liquidity_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_period_first_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_categ AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_val_balance AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_tr_ac AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_tr_pl AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_liquidity_account AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_compens_account AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_int_no_booking AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_min_value AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_min_waive AS string))), ''), 256) AS hd_accr_acct_cr_information,
    sha2(COALESCE(UPPER(TRIM(CAST(t_cr_int_tax_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_tax_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_tax_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_taxcateg AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_taxtrsdr AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_int_taxtrscr AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_tax_for_customer AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_tax_for_bank AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_post_interest AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_main_acct AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_dist_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_dist_ratio AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_int_categ AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_tr_ac AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_tr_pl AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_main_int AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ica_sub_int AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_correction_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_unadj_total_int AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_tax_exch_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_manual_adj_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_correction_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_adj_int_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_adj_tax_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_withheld_int_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_db_netting_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_correction_date AS string))), ''), 256) AS hd_accr_acct_cr_other,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_period_last_date, t_int_post_date, t_cr_no_of_days, t_cr_int_amt, t_total_interest, t_grand_total,
    t_liquidity_ccy, t_period_first_date, t_cr_int_rate, t_cr_int_date, t_cr_int_categ, t_cr_val_balance,
    t_cr_int_tr_ac, t_cr_int_tr_pl, t_liquidity_account, t_compens_account, t_int_no_booking, t_cr_min_value, t_cr_min_waive,
    t_cr_int_tax_code, t_cr_int_tax_rate, t_cr_int_tax_amt, t_cr_int_taxcateg, t_cr_int_taxtrsdr, t_cr_int_taxtrscr,
    t_tax_for_customer, t_tax_for_bank, t_ica_post_interest, t_ica_main_acct, t_ica_dist_type, t_ica_dist_ratio,
    t_ica_int_categ, t_ica_tr_ac, t_ica_tr_pl, t_ica_main_int, t_ica_sub_int, t_correction_number,
    t_unadj_total_int, t_tax_exch_rate, t_manual_adj_amt, t_correction_id, t_adj_int_amt, t_adj_tax_amt,
    t_withheld_int_amt, t_db_netting_amt, t_correction_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_accr_acct_cr')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_accr_acct_dr_s; CREATE TEMPORARY TABLE tmp_t24_accr_acct_dr_s AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS account_hashkey,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_accr_acct_dr')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_acct_activity_s; CREATE TEMPORARY TABLE tmp_t24_acct_activity_s AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(split_part(id, '-', 1) AS string))), ''), 256) AS account_hashkey,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    trim(split_part(id, '-', 1)) AS account_bk
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_acct_activity')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_stmt_acct_cr_s; CREATE TEMPORARY TABLE tmp_t24_stmt_acct_cr_s AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(split_part(id, '-', 1) AS string))), ''), 256) AS account_hashkey,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    trim(split_part(id, '-', 1)) AS account_bk
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_stmt_acct_cr')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_stmt_acct_dr_s; CREATE TEMPORARY TABLE tmp_t24_stmt_acct_dr_s AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(split_part(id, '-', 1) AS string))), ''), 256) AS account_hashkey,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    trim(split_part(id, '-', 1)) AS account_bk
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_stmt_acct_dr')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_ocbh_ac_restrict_s; CREATE TEMPORARY TABLE tmp_t24_ocbh_ac_restrict_s AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS account_hashkey,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_ocbh_ac_restrict')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_account] Consolidated insert from all 6 sources to avoid Delta version conflicts when running in parallel
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_account')
(account_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH all_sources AS (
    SELECT account_hashkey, CAST(id AS STRING) AS business_key, source_event_date, 't24__t24_accr_acct_cr' AS record_source, data_date, 2 AS source_priority
    FROM tmp_t24_accr_acct_cr
    UNION ALL
    SELECT account_hashkey, CAST(id AS STRING), source_event_date, 't24__t24_accr_acct_dr', data_date, 2
    FROM tmp_t24_accr_acct_dr_s
    UNION ALL
    SELECT account_hashkey, account_bk, source_event_date, 't24__t24_acct_activity', data_date, 2
    FROM tmp_t24_acct_activity_s
    UNION ALL
    SELECT account_hashkey, CAST(id AS STRING), source_event_date, 't24__t24_ocbh_ac_restrict', data_date, 2
    FROM tmp_t24_ocbh_ac_restrict_s
    UNION ALL
    SELECT account_hashkey, account_bk, source_event_date, 't24__t24_stmt_acct_cr', data_date, 2
    FROM tmp_t24_stmt_acct_cr_s
    UNION ALL
    SELECT account_hashkey, account_bk, source_event_date, 't24__t24_stmt_acct_dr', data_date, 2
    FROM tmp_t24_stmt_acct_dr_s
),
deduped AS (SELECT * FROM all_sources QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey ORDER BY data_date, source_priority) = 1)
SELECT d.account_hashkey, d.business_key, d.source_event_date, current_timestamp(), d.record_source
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_account') t
    ON t.account_hashkey = d.account_hashkey;

-- [sts_hub_account_accr_acct_cr] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_accr_acct_cr')
(account_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_accr_acct_cr
),
present_per_date AS (
    SELECT DISTINCT account_hashkey, source_event_date FROM tmp_t24_accr_acct_cr
),
full_timeline AS (
    SELECT DISTINCT h.account_hashkey, d.source_event_date,
           CASE WHEN p.account_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_account') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.account_hashkey = h.account_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT account_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY account_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT account_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_accr_acct_cr')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_accr_acct_cr)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.account_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.account_hashkey = t.account_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.account_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.account_hashkey = t.account_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.account_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_accr_acct_cr') t
    ON t.account_hashkey = sc.account_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sts_hub_account_accr_acct_dr] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_accr_acct_dr')
(account_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_accr_acct_dr_s
),
present_per_date AS (
    SELECT DISTINCT account_hashkey, source_event_date FROM tmp_t24_accr_acct_dr_s
),
full_timeline AS (
    SELECT DISTINCT h.account_hashkey, d.source_event_date,
           CASE WHEN p.account_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_account') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.account_hashkey = h.account_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT account_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY account_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT account_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_accr_acct_dr')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_accr_acct_dr_s)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    SELECT t.account_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.account_hashkey = t.account_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    SELECT t.account_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.account_hashkey = t.account_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.account_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_accr_acct_dr') t
    ON t.account_hashkey = sc.account_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sts_hub_account_acct_activity] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_acct_activity')
(account_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_acct_activity_s
),
present_per_date AS (
    SELECT DISTINCT account_hashkey, source_event_date FROM tmp_t24_acct_activity_s
),
full_timeline AS (
    SELECT DISTINCT h.account_hashkey, d.source_event_date,
           CASE WHEN p.account_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_account') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.account_hashkey = h.account_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT account_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY account_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT account_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_acct_activity')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_acct_activity_s)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    SELECT t.account_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.account_hashkey = t.account_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    SELECT t.account_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.account_hashkey = t.account_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.account_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_acct_activity') t
    ON t.account_hashkey = sc.account_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sts_hub_account_stmt_acct_cr] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_stmt_acct_cr')
(account_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_stmt_acct_cr_s
),
present_per_date AS (
    SELECT DISTINCT account_hashkey, source_event_date FROM tmp_t24_stmt_acct_cr_s
),
full_timeline AS (
    SELECT DISTINCT h.account_hashkey, d.source_event_date,
           CASE WHEN p.account_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_account') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.account_hashkey = h.account_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT account_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY account_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT account_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_stmt_acct_cr')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_stmt_acct_cr_s)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    SELECT t.account_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.account_hashkey = t.account_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    SELECT t.account_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.account_hashkey = t.account_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.account_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_stmt_acct_cr') t
    ON t.account_hashkey = sc.account_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sts_hub_account_stmt_acct_dr] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_stmt_acct_dr')
(account_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_stmt_acct_dr_s
),
present_per_date AS (
    SELECT DISTINCT account_hashkey, source_event_date FROM tmp_t24_stmt_acct_dr_s
),
full_timeline AS (
    SELECT DISTINCT h.account_hashkey, d.source_event_date,
           CASE WHEN p.account_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_account') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.account_hashkey = h.account_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT account_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY account_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT account_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_stmt_acct_dr')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_stmt_acct_dr_s)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    SELECT t.account_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.account_hashkey = t.account_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    SELECT t.account_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.account_hashkey = t.account_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.account_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_stmt_acct_dr') t
    ON t.account_hashkey = sc.account_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sts_hub_account_ac_restrict] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_ac_restrict')
(account_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_ocbh_ac_restrict_s
),
present_per_date AS (
    SELECT DISTINCT account_hashkey, source_event_date FROM tmp_t24_ocbh_ac_restrict_s
),
full_timeline AS (
    SELECT DISTINCT h.account_hashkey, d.source_event_date,
           CASE WHEN p.account_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_account') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.account_hashkey = h.account_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT account_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY account_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT account_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_ac_restrict')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_ocbh_ac_restrict_s)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    SELECT t.account_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.account_hashkey = t.account_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    SELECT t.account_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.account_hashkey = t.account_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.account_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_ac_restrict') t
    ON t.account_hashkey = sc.account_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_accr_acct_cr_dynamic] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_accr_acct_cr_dynamic')
(account_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_period_last_date, t_int_post_date, t_cr_no_of_days, t_cr_int_amt, t_total_interest, t_grand_total)
WITH last_known AS (
    SELECT account_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_accr_acct_cr_dynamic')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_accr_acct_cr_dynamic) OVER (PARTITION BY s.account_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_accr_acct_cr s
    LEFT JOIN last_known lk ON lk.account_hashkey = s.account_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_accr_acct_cr_dynamic != prev_hashdiff)
SELECT d.account_hashkey, d.hd_accr_acct_cr_dynamic, d.source_event_date, current_timestamp(), 't24__t24_accr_acct_cr',
       d.t_period_last_date, d.t_int_post_date, d.t_cr_no_of_days, d.t_cr_int_amt, d.t_total_interest, d.t_grand_total
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_accr_acct_cr_dynamic') t ON t.account_hashkey = d.account_hashkey AND t.source_event_date = d.source_event_date;

-- [sat_accr_acct_cr_information] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_accr_acct_cr_information')
(account_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_liquidity_ccy, t_period_first_date, t_cr_int_rate, t_cr_int_date, t_cr_int_categ, t_cr_val_balance,
 t_cr_int_tr_ac, t_cr_int_tr_pl, t_liquidity_account, t_compens_account, t_int_no_booking, t_cr_min_value, t_cr_min_waive)
WITH last_known AS (
    SELECT account_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_accr_acct_cr_information')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_accr_acct_cr_information) OVER (PARTITION BY s.account_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_accr_acct_cr s
    LEFT JOIN last_known lk ON lk.account_hashkey = s.account_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_accr_acct_cr_information != prev_hashdiff)
SELECT d.account_hashkey, d.hd_accr_acct_cr_information, d.source_event_date, current_timestamp(), 't24__t24_accr_acct_cr',
       d.t_liquidity_ccy, d.t_period_first_date, d.t_cr_int_rate, d.t_cr_int_date, d.t_cr_int_categ, d.t_cr_val_balance,
       d.t_cr_int_tr_ac, d.t_cr_int_tr_pl, d.t_liquidity_account, d.t_compens_account, d.t_int_no_booking, d.t_cr_min_value, d.t_cr_min_waive
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_accr_acct_cr_information') t ON t.account_hashkey = d.account_hashkey AND t.source_event_date = d.source_event_date;

-- [sat_accr_acct_cr_other] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_accr_acct_cr_other')
(account_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_cr_int_tax_code, t_cr_int_tax_rate, t_cr_int_tax_amt, t_cr_int_taxcateg, t_cr_int_taxtrsdr, t_cr_int_taxtrscr,
 t_tax_for_customer, t_tax_for_bank, t_ica_post_interest, t_ica_main_acct, t_ica_dist_type, t_ica_dist_ratio,
 t_ica_int_categ, t_ica_tr_ac, t_ica_tr_pl, t_ica_main_int, t_ica_sub_int, t_correction_number,
 t_unadj_total_int, t_tax_exch_rate, t_manual_adj_amt, t_correction_id, t_adj_int_amt, t_adj_tax_amt,
 t_withheld_int_amt, t_db_netting_amt, t_correction_date)
WITH last_known AS (
    SELECT account_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_accr_acct_cr_other')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY account_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_accr_acct_cr_other) OVER (PARTITION BY s.account_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_accr_acct_cr s
    LEFT JOIN last_known lk ON lk.account_hashkey = s.account_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_accr_acct_cr_other != prev_hashdiff)
SELECT d.account_hashkey, d.hd_accr_acct_cr_other, d.source_event_date, current_timestamp(), 't24__t24_accr_acct_cr',
       d.t_cr_int_tax_code, d.t_cr_int_tax_rate, d.t_cr_int_tax_amt, d.t_cr_int_taxcateg, d.t_cr_int_taxtrsdr, d.t_cr_int_taxtrscr,
       d.t_tax_for_customer, d.t_tax_for_bank, d.t_ica_post_interest, d.t_ica_main_acct, d.t_ica_dist_type, d.t_ica_dist_ratio,
       d.t_ica_int_categ, d.t_ica_tr_ac, d.t_ica_tr_pl, d.t_ica_main_int, d.t_ica_sub_int, d.t_correction_number,
       d.t_unadj_total_int, d.t_tax_exch_rate, d.t_manual_adj_amt, d.t_correction_id, d.t_adj_int_amt, d.t_adj_tax_amt,
       d.t_withheld_int_amt, d.t_db_netting_amt, d.t_correction_date
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_accr_acct_cr_other') t ON t.account_hashkey = d.account_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_accr_acct_cr;
DROP TEMPORARY TABLE IF EXISTS tmp_t24_accr_acct_dr_s;
DROP TEMPORARY TABLE IF EXISTS tmp_t24_acct_activity_s;
DROP TEMPORARY TABLE IF EXISTS tmp_t24_stmt_acct_cr_s;
DROP TEMPORARY TABLE IF EXISTS tmp_t24_stmt_acct_dr_s;
DROP TEMPORARY TABLE IF EXISTS tmp_t24_ocbh_ac_restrict_s;
