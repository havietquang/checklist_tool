-- Source: .t24.t24_diary
-- Target: :catalog_cleaned.raw_vault
--   hub_diary, sts_hub_diary, sat_diary_information, sat_diary_system
--   link_diary_security
-- Phase2: priority 1 source for hub_diary.
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_diary; CREATE TEMPORARY TABLE tmp_t24_diary AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS diary_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_security_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_narrative AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_event_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_depository AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ex_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pay_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_value_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_currency AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rate_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_option_desc AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_percentage AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_commission_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_net_charges AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_bond_share_flag AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_dep_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_dep_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_dep_account_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_total_cash AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_total_cash_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_total_cash_xch AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_total_cash_lccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rp_tot_cash AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rp_tot_cash_lcy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_tot_security AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_option AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_accrual_start_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_portfolio_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cash_hold_settle AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_sec_hold_settle AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_total_credit AS string))), ''), 256) AS hd_diary_information,
    sha2(COALESCE(UPPER(TRIM(CAST(t_vault_update AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_local_tax_perc AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_total_debit AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_option_nominal AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_option1 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_opt1_depot AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_opt1_nominal AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_opt1_cash AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_opt1_cash_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_opt1_sec AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_opt1_debit AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_auto_update AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_source AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cash_hold_settle AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_sec_hold_settle AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_total_credit AS string))), ''), 256) AS hd_diary_system,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_security_no AS string))), ''), 256) AS link_diary_security_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_security_no AS string))), ''), 256) AS security_hashkey,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_security_no, t_narrative, t_event_type, t_depository, t_ex_date, t_pay_date, t_value_date,
    t_currency, t_rate_type, t_option_desc, t_rate, t_percentage, t_commission_code, t_net_charges,
    t_bond_share_flag, t_dep_no, t_dep_type, t_dep_account_no, t_total_cash, t_total_cash_ccy,
    t_total_cash_xch, t_total_cash_lccy, t_rp_tot_cash, t_rp_tot_cash_lcy, t_tot_security,
    t_option, t_accrual_start_date, t_portfolio_no, t_cash_hold_settle, t_sec_hold_settle, t_total_credit,
    t_vault_update, t_local_tax_perc, t_total_debit, t_option_nominal, t_option1, t_opt1_depot,
    t_opt1_nominal, t_opt1_cash, t_opt1_cash_ccy, t_opt1_sec, t_opt1_debit, t_auto_update, t_source
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_diary')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_entitlement_s; CREATE TEMPORARY TABLE tmp_t24_entitlement_s AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(split_part(id, '-', 1) AS string))), ''), 256) AS diary_hashkey,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    trim(split_part(id, '-', 1)) AS diary_bk
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_entitlement')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_diary] Consolidated insert from t24_diary and t24_entitlement sources to avoid Delta version conflicts
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_diary')
(diary_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH all_sources AS (
    SELECT diary_hashkey, CAST(id AS STRING) AS business_key, source_event_date, 't24__t24_diary' AS record_source, data_date, 1 AS source_priority
    FROM tmp_t24_diary
    UNION ALL
    SELECT diary_hashkey, diary_bk, source_event_date, 't24__t24_entitlement' AS record_source, data_date, 2 AS source_priority
    FROM tmp_t24_entitlement_s
),
deduped AS (SELECT * FROM all_sources QUALIFY ROW_NUMBER() OVER (PARTITION BY diary_hashkey ORDER BY data_date, source_priority) = 1)
SELECT d.diary_hashkey, d.business_key, d.source_event_date, current_timestamp(), d.record_source
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_diary') t
    ON t.diary_hashkey = d.diary_hashkey;

-- [sts_hub_diary] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_diary')
(diary_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_diary
),
present_per_date AS (
    SELECT DISTINCT diary_hashkey, source_event_date FROM tmp_t24_diary
),
full_timeline AS (
    SELECT DISTINCT h.diary_hashkey, d.source_event_date,
           CASE WHEN p.diary_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_diary') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.diary_hashkey = h.diary_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT diary_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY diary_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT diary_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_diary')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_diary)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY diary_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.diary_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.diary_hashkey = t.diary_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.diary_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.diary_hashkey = t.diary_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.diary_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_diary') t
    ON t.diary_hashkey = sc.diary_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sts_hub_diary_entitlement] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_diary_entitlement')
(diary_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_entitlement_s
),
present_per_date AS (
    SELECT DISTINCT diary_hashkey, source_event_date FROM tmp_t24_entitlement_s
),
full_timeline AS (
    SELECT DISTINCT h.diary_hashkey, d.source_event_date,
           CASE WHEN p.diary_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_diary') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.diary_hashkey = h.diary_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT diary_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY diary_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT diary_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_diary_entitlement')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_entitlement_s)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY diary_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.diary_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.diary_hashkey = t.diary_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.diary_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.diary_hashkey = t.diary_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.diary_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_diary_entitlement') t
    ON t.diary_hashkey = sc.diary_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_diary_information] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_diary_information')
(diary_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_security_no, t_narrative, t_event_type, t_depository, t_ex_date, t_pay_date, t_value_date,
 t_currency, t_rate_type, t_option_desc, t_rate, t_percentage, t_commission_code, t_net_charges,
 t_bond_share_flag, t_dep_no, t_dep_type, t_dep_account_no, t_total_cash, t_total_cash_ccy,
 t_total_cash_xch, t_total_cash_lccy, t_rp_tot_cash, t_rp_tot_cash_lcy, t_tot_security,
 t_option, t_accrual_start_date, t_portfolio_no, t_cash_hold_settle, t_sec_hold_settle, t_total_credit)
WITH last_known AS (
    SELECT diary_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_diary_information')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY diary_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_diary_information) OVER (PARTITION BY s.diary_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_diary s
    LEFT JOIN last_known lk ON lk.diary_hashkey = s.diary_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_diary_information != prev_hashdiff)
SELECT d.diary_hashkey, d.hd_diary_information, d.source_event_date, current_timestamp(), 't24__t24_diary',
       d.t_security_no, d.t_narrative, d.t_event_type, d.t_depository, d.t_ex_date, d.t_pay_date, d.t_value_date,
       d.t_currency, d.t_rate_type, d.t_option_desc, d.t_rate, d.t_percentage, d.t_commission_code, d.t_net_charges,
       d.t_bond_share_flag, d.t_dep_no, d.t_dep_type, d.t_dep_account_no, d.t_total_cash, d.t_total_cash_ccy,
       d.t_total_cash_xch, d.t_total_cash_lccy, d.t_rp_tot_cash, d.t_rp_tot_cash_lcy, d.t_tot_security,
       d.t_option, d.t_accrual_start_date, d.t_portfolio_no, d.t_cash_hold_settle, d.t_sec_hold_settle, d.t_total_credit
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_diary_information') t ON t.diary_hashkey = d.diary_hashkey AND t.source_event_date = d.source_event_date;

-- [sat_diary_system] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_diary_system')
(diary_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_vault_update, t_local_tax_perc, t_total_debit, t_option_nominal, t_option1, t_opt1_depot,
 t_opt1_nominal, t_opt1_cash, t_opt1_cash_ccy, t_opt1_sec, t_opt1_debit, t_auto_update, t_source,
 t_cash_hold_settle, t_sec_hold_settle, t_total_credit)
WITH last_known AS (
    SELECT diary_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_diary_system')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY diary_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_diary_system) OVER (PARTITION BY s.diary_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_diary s
    LEFT JOIN last_known lk ON lk.diary_hashkey = s.diary_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_diary_system != prev_hashdiff)
SELECT d.diary_hashkey, d.hd_diary_system, d.source_event_date, current_timestamp(), 't24__t24_diary',
       d.t_vault_update, d.t_local_tax_perc, d.t_total_debit, d.t_option_nominal, d.t_option1, d.t_opt1_depot,
       d.t_opt1_nominal, d.t_opt1_cash, d.t_opt1_cash_ccy, d.t_opt1_sec, d.t_opt1_debit, d.t_auto_update, d.t_source,
       d.t_cash_hold_settle, d.t_sec_hold_settle, d.t_total_credit
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_diary_system') t ON t.diary_hashkey = d.diary_hashkey AND t.source_event_date = d.source_event_date;

-- [link_diary_security] Insert new relationships (ANTI JOIN on link hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_diary_security')
(link_diary_security_hashkey, diary_hashkey, security_hashkey, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_diary WHERE t_security_no IS NOT NULL QUALIFY ROW_NUMBER() OVER (PARTITION BY link_diary_security_hashkey ORDER BY data_date) = 1)
SELECT d.link_diary_security_hashkey, d.diary_hashkey, d.security_hashkey, d.source_event_date, current_timestamp(), 't24__t24_diary'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_diary_security') t
    ON t.link_diary_security_hashkey = d.link_diary_security_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_diary;
DROP TEMPORARY TABLE IF EXISTS tmp_t24_entitlement_s;
