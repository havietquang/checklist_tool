-- Source: .t24.t24_security_position
-- Target: :catalog_cleaned.raw_vault
--   hub_security, sts_hub_security_position, sat_security_position
-- Phase2 addition: priority 2 source. business_key = t_security_number, ma_key = id
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_security_position; CREATE TEMPORARY TABLE tmp_t24_security_position AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(t_security_number AS string))), ''), 256) AS security_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_book_cost_sec_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cap_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_closing_bal_no_nom AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cost_invst_bse_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cost_invst_ref_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cost_invst_sec_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_last_traded AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_depository AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_fin_company AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_gr_bk_cost_sec_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_gross_cost_sec_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_held_since AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_income_curr_period AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_issue_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_nom_amt_blocked AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_opening_bal_no_nom AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_security_account AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_urlz_ccy_gn_cr_ptf AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_urlz_mrk_gn_cr_ptf AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_val_dat_book_cost AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_value_dat_cost_ref AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_value_dated_cost AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_value_dated_posn AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ytd_invst_sec_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amt_blocked AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_reference_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_nominee_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_maturity_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_interest_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_opn_cost_invst_sec AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_opn_cost_invst_ptf AS string))), ''), 256) AS hd_security_position,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    t_security_number,
    id AS ma_key,
    t_book_cost_sec_ccy, t_cap_amt, t_closing_bal_no_nom, t_cost_invst_bse_ccy, t_cost_invst_ref_ccy,
    t_cost_invst_sec_ccy, t_date_last_traded, t_depository, t_fin_company, t_gr_bk_cost_sec_ccy,
    t_gross_cost_sec_ccy, t_held_since, t_income_curr_period, t_issue_date, t_nom_amt_blocked,
    t_opening_bal_no_nom, t_security_account, t_urlz_ccy_gn_cr_ptf, t_urlz_mrk_gn_cr_ptf,
    t_val_dat_book_cost, t_value_dat_cost_ref, t_value_dated_cost, t_value_dated_posn,
    t_ytd_invst_sec_ccy, t_amt_blocked, t_reference_number, t_nominee_code,
    t_maturity_date, t_interest_rate, t_opn_cost_invst_sec, t_opn_cost_invst_ptf
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_security_position')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND t_security_number IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_ocbh_scm_extra_info_s; CREATE TEMPORARY TABLE tmp_t24_ocbh_scm_extra_info_s AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS security_hashkey,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_ocbh_scm_extra_info')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_security] Consolidated insert from t24_security_position and t24_ocbh_scm_extra_info sources to avoid Delta version conflicts
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_security')
(security_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH all_sources AS (
    SELECT security_hashkey, CAST(t_security_number AS STRING) AS business_key, source_event_date, 't24__t24_security_position' AS record_source, data_date, 2 AS source_priority
    FROM tmp_t24_security_position
    UNION ALL
    SELECT security_hashkey, CAST(id AS STRING), source_event_date, 't24__t24_ocbh_scm_extra_info', data_date, 2
    FROM tmp_t24_ocbh_scm_extra_info_s
),
deduped AS (SELECT * FROM all_sources QUALIFY ROW_NUMBER() OVER (PARTITION BY security_hashkey ORDER BY data_date, source_priority) = 1)
SELECT d.security_hashkey, d.business_key, d.source_event_date, current_timestamp(), d.record_source
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_security') t
    ON t.security_hashkey = d.security_hashkey;

-- [sts_hub_security_position] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_security_position')
(security_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_security_position
),
present_per_date AS (
    SELECT DISTINCT security_hashkey, source_event_date FROM tmp_t24_security_position
),
full_timeline AS (
    SELECT DISTINCT h.security_hashkey, d.source_event_date,
           CASE WHEN p.security_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_security') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.security_hashkey = h.security_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT security_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY security_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT security_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_security_position')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_security_position)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY security_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.security_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.security_hashkey = t.security_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.security_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.security_hashkey = t.security_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.security_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_security_position') t
    ON t.security_hashkey = sc.security_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sts_hub_security_scm_extra_info] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_security_scm_extra_info')
(security_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_ocbh_scm_extra_info_s
),
present_per_date AS (
    SELECT DISTINCT security_hashkey, source_event_date FROM tmp_t24_ocbh_scm_extra_info_s
),
full_timeline AS (
    SELECT DISTINCT h.security_hashkey, d.source_event_date,
           CASE WHEN p.security_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_security') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.security_hashkey = h.security_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT security_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY security_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT security_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_security_scm_extra_info')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_ocbh_scm_extra_info_s)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY security_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    SELECT t.security_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.security_hashkey = t.security_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    SELECT t.security_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.security_hashkey = t.security_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.security_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_security_scm_extra_info') t
    ON t.security_hashkey = sc.security_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_security_position] Multi-value satellite — compare with latest per (security_hashkey, ma_key)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_security_position')
(security_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, t_book_cost_sec_ccy, t_cap_amt, t_closing_bal_no_nom, t_cost_invst_bse_ccy, t_cost_invst_ref_ccy,
 t_cost_invst_sec_ccy, t_date_last_traded, t_depository, t_fin_company, t_gr_bk_cost_sec_ccy,
 t_gross_cost_sec_ccy, t_held_since, t_income_curr_period, t_issue_date, t_nom_amt_blocked,
 t_opening_bal_no_nom, t_security_account, t_urlz_ccy_gn_cr_ptf, t_urlz_mrk_gn_cr_ptf,
 t_val_dat_book_cost, t_value_dat_cost_ref, t_value_dated_cost, t_value_dated_posn,
 t_ytd_invst_sec_ccy, t_amt_blocked, t_reference_number, t_nominee_code,
 t_maturity_date, t_interest_rate, t_opn_cost_invst_sec, t_opn_cost_invst_ptf)
WITH last_known AS (
    SELECT security_hashkey, ma_key, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_security_position')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY security_hashkey, ma_key ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_security_position) OVER (PARTITION BY s.security_hashkey, s.ma_key ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_security_position s
    LEFT JOIN last_known lk ON lk.security_hashkey = s.security_hashkey AND lk.ma_key = s.ma_key
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_security_position != prev_hashdiff)
SELECT d.security_hashkey, d.hd_security_position, d.source_event_date, current_timestamp(), 't24__t24_security_position',
       d.ma_key, d.t_book_cost_sec_ccy, d.t_cap_amt, d.t_closing_bal_no_nom, d.t_cost_invst_bse_ccy, d.t_cost_invst_ref_ccy,
       d.t_cost_invst_sec_ccy, d.t_date_last_traded, d.t_depository, d.t_fin_company, d.t_gr_bk_cost_sec_ccy,
       d.t_gross_cost_sec_ccy, d.t_held_since, d.t_income_curr_period, d.t_issue_date, d.t_nom_amt_blocked,
       d.t_opening_bal_no_nom, d.t_security_account, d.t_urlz_ccy_gn_cr_ptf, d.t_urlz_mrk_gn_cr_ptf,
       d.t_val_dat_book_cost, d.t_value_dat_cost_ref, d.t_value_dated_cost, d.t_value_dated_posn,
       d.t_ytd_invst_sec_ccy, d.t_amt_blocked, d.t_reference_number, d.t_nominee_code,
       d.t_maturity_date, d.t_interest_rate, d.t_opn_cost_invst_sec, d.t_opn_cost_invst_ptf
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_security_position') t ON t.security_hashkey = d.security_hashkey AND t.ma_key = d.ma_key AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_security_position;
DROP TEMPORARY TABLE IF EXISTS tmp_t24_ocbh_scm_extra_info_s;
