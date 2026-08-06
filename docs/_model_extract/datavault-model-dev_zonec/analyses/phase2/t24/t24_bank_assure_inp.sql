-- Source: .t24.t24_bank_assure_inp
-- Target: :catalog_cleaned.raw_vault
--   hub_loans, sts_hub_loans_bank_assure_inp, sat_bank_assure_inp
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_bank_assure_inp; CREATE TEMPORARY TABLE tmp_t24_bank_assure_inp AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(t_contract_ld AS string))), ''), 256) AS loans_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ccy_assr AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cr_product_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_assr_request_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_assr_begin_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_assr_end_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_fee_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pay_fee_period AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_first_term_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_next_fee_cal_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_next_int_begin_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_next_int_end_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_loan_amount AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_paid_int_freq AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_paid_ori_freq AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_advisory_cadre AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_info_note AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_first_fee_cal_date AS string))), ''), 256) AS hd_bank_assure_inp,
    id AS ma_key,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    t_contract_ld, id,
    t_ccy_assr, t_cr_product_code, t_assr_request_date, t_assr_begin_date, t_assr_end_date,
    t_fee_rate, t_pay_fee_period, t_first_term_amt, t_next_fee_cal_date, t_next_int_begin_date,
    t_next_int_end_date, t_loan_amount, t_paid_int_freq, t_paid_ori_freq, t_advisory_cadre,
    t_info_note, t_co_code, t_first_fee_cal_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_bank_assure_inp')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND t_contract_ld IS NOT NULL;

-- [hub_loans] Insert business keys not yet in hub (ANTI JOIN on hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_loans')
(loans_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_bank_assure_inp QUALIFY ROW_NUMBER() OVER (PARTITION BY loans_hashkey ORDER BY data_date) = 1)
SELECT d.loans_hashkey, CAST(d.t_contract_ld AS STRING), d.source_event_date, current_timestamp(), 't24__t24_bank_assure_inp'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_loans') t
    ON t.loans_hashkey = d.loans_hashkey;

-- [sts_hub_loans_bank_assure_inp] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_loans_bank_assure_inp')
(loans_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_bank_assure_inp
),
present_per_date AS (
    SELECT DISTINCT loans_hashkey, source_event_date FROM tmp_t24_bank_assure_inp
),
full_timeline AS (
    SELECT DISTINCT h.loans_hashkey, d.source_event_date,
           CASE WHEN p.loans_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_loans') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.loans_hashkey = h.loans_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT loans_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY loans_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT loans_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_loans_bank_assure_inp')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_bank_assure_inp)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY loans_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.loans_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.loans_hashkey = t.loans_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.loans_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.loans_hashkey = t.loans_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.loans_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_loans_bank_assure_inp') t
    ON t.loans_hashkey = sc.loans_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_bank_assure_inp] Multi-value satellite — compare with latest per (loans_hashkey, ma_key)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_bank_assure_inp')
(loans_hashkey, ma_key, hashdiff, source_event_date, load_timestamp, record_source,
 t_ccy_assr, t_cr_product_code, t_assr_request_date, t_assr_begin_date, t_assr_end_date,
 t_fee_rate, t_pay_fee_period, t_first_term_amt, t_next_fee_cal_date, t_next_int_begin_date,
 t_next_int_end_date, t_loan_amount, t_paid_int_freq, t_paid_ori_freq, t_advisory_cadre,
 t_info_note, t_co_code, t_first_fee_cal_date)
WITH last_known AS (
    SELECT loans_hashkey, ma_key, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_bank_assure_inp')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY loans_hashkey, ma_key ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_bank_assure_inp) OVER (PARTITION BY s.loans_hashkey, s.ma_key ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_bank_assure_inp s
    LEFT JOIN last_known lk ON lk.loans_hashkey = s.loans_hashkey AND lk.ma_key = s.ma_key
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_bank_assure_inp != prev_hashdiff)
SELECT d.loans_hashkey, d.ma_key, d.hd_bank_assure_inp, d.source_event_date, current_timestamp(), 't24__t24_bank_assure_inp',
       d.t_ccy_assr, d.t_cr_product_code, d.t_assr_request_date, d.t_assr_begin_date, d.t_assr_end_date,
       d.t_fee_rate, d.t_pay_fee_period, d.t_first_term_amt, d.t_next_fee_cal_date, d.t_next_int_begin_date,
       d.t_next_int_end_date, d.t_loan_amount, d.t_paid_int_freq, d.t_paid_ori_freq, d.t_advisory_cadre,
       d.t_info_note, d.t_co_code, d.t_first_fee_cal_date
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_bank_assure_inp') t ON t.loans_hashkey = d.loans_hashkey AND t.ma_key = d.ma_key AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_bank_assure_inp;
