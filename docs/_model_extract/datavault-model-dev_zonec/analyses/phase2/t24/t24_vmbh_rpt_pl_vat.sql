-- Source: .t24.t24_vmbh_rpt_pl_vat
-- Target: :catalog_cleaned.raw_vault
--   hub_rpt_pl_vat, sts_hub_rpt_pl_vat, sat_rpt_pl_vat
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_vmbh_rpt_pl_vat; CREATE TEMPORARY TABLE tmp_t24_vmbh_rpt_pl_vat AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS rpt_pl_vat_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_begin_bal AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_buy_month AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_avr_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_sell_month AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_buy_avr_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pl_current AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pl_accumulate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_tot_pl_month AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_tot_vat_month AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_tot_vat_prev AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_vat_pay_month AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_vat_carry_fwd AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_reserved_1 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_dept_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_auditor_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_audit_date_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_tot_pl_prev AS string))), ''), 256) AS hd_rpt_pl_vat,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_begin_bal, t_buy_month, t_avr_rate, t_sell_month, t_buy_avr_rate, t_pl_current, t_pl_accumulate,
    t_tot_pl_month, t_tot_vat_month, t_tot_vat_prev, t_vat_pay_month, t_vat_carry_fwd, t_reserved_1,
    t_record_status, t_curr_no, t_inputter, t_date_time, t_authoriser, t_co_code, t_dept_code,
    t_auditor_code, t_audit_date_time, t_tot_pl_prev
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_vmbh_rpt_pl_vat')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_rpt_pl_vat] Insert business keys not yet in hub (ANTI JOIN on hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_rpt_pl_vat')
(rpt_pl_vat_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_vmbh_rpt_pl_vat QUALIFY ROW_NUMBER() OVER (PARTITION BY rpt_pl_vat_hashkey ORDER BY data_date) = 1)
SELECT d.rpt_pl_vat_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 't24__t24_vmbh_rpt_pl_vat'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_rpt_pl_vat') t
    ON t.rpt_pl_vat_hashkey = d.rpt_pl_vat_hashkey;

-- [sts_hub_rpt_pl_vat] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_rpt_pl_vat')
(rpt_pl_vat_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_vmbh_rpt_pl_vat
),
present_per_date AS (
    SELECT DISTINCT rpt_pl_vat_hashkey, source_event_date FROM tmp_t24_vmbh_rpt_pl_vat
),
full_timeline AS (
    SELECT DISTINCT h.rpt_pl_vat_hashkey, d.source_event_date,
           CASE WHEN p.rpt_pl_vat_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_rpt_pl_vat') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.rpt_pl_vat_hashkey = h.rpt_pl_vat_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT rpt_pl_vat_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY rpt_pl_vat_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT rpt_pl_vat_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_rpt_pl_vat')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_vmbh_rpt_pl_vat)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY rpt_pl_vat_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.rpt_pl_vat_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.rpt_pl_vat_hashkey = t.rpt_pl_vat_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.rpt_pl_vat_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.rpt_pl_vat_hashkey = t.rpt_pl_vat_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.rpt_pl_vat_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_rpt_pl_vat') t
    ON t.rpt_pl_vat_hashkey = sc.rpt_pl_vat_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_rpt_pl_vat] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_rpt_pl_vat')
(rpt_pl_vat_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_begin_bal, t_buy_month, t_avr_rate, t_sell_month, t_buy_avr_rate, t_pl_current, t_pl_accumulate,
 t_tot_pl_month, t_tot_vat_month, t_tot_vat_prev, t_vat_pay_month, t_vat_carry_fwd, t_reserved_1,
 t_record_status, t_curr_no, t_inputter, t_date_time, t_authoriser, t_co_code, t_dept_code,
 t_auditor_code, t_audit_date_time, t_tot_pl_prev)
WITH last_known AS (
    SELECT rpt_pl_vat_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_rpt_pl_vat')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY rpt_pl_vat_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_rpt_pl_vat) OVER (PARTITION BY s.rpt_pl_vat_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_vmbh_rpt_pl_vat s
    LEFT JOIN last_known lk ON lk.rpt_pl_vat_hashkey = s.rpt_pl_vat_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_rpt_pl_vat != prev_hashdiff)
SELECT d.rpt_pl_vat_hashkey, d.hd_rpt_pl_vat, d.source_event_date, current_timestamp(), 't24__t24_vmbh_rpt_pl_vat',
       d.t_begin_bal, d.t_buy_month, d.t_avr_rate, d.t_sell_month, d.t_buy_avr_rate, d.t_pl_current, d.t_pl_accumulate,
       d.t_tot_pl_month, d.t_tot_vat_month, d.t_tot_vat_prev, d.t_vat_pay_month, d.t_vat_carry_fwd, d.t_reserved_1,
       d.t_record_status, d.t_curr_no, d.t_inputter, d.t_date_time, d.t_authoriser, d.t_co_code, d.t_dept_code,
       d.t_auditor_code, d.t_audit_date_time, d.t_tot_pl_prev
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_rpt_pl_vat') t ON t.rpt_pl_vat_hashkey = d.rpt_pl_vat_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_vmbh_rpt_pl_vat;
