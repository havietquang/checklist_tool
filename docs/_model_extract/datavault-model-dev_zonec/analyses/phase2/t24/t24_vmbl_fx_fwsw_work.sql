-- Source: .t24.t24_vmbl_fx_fwsw_work
-- Target: :catalog_cleaned.raw_vault
--   hub_fx_fwsw_work, sts_hub_fx_fwsw_work, sat_fx_fwsw_work, sat_fx_fwsw_work_dynamic
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_vmbl_fx_fwsw_work; CREATE TEMPORARY TABLE tmp_t24_vmbl_fx_fwsw_work AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS fx_fwsw_work_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_fx_contract AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_deal_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_deal_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ccy_bought AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amt_bought AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ccy_sold AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amt_sold AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_spot_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_fwd_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_no_days AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_profit_loss AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_dly_amort AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_last_amort AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_base AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_value_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_lcy_equiv AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_lcy_dly_amort AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_lcy_last_amort AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_lcy_profit_loss AS string))), ''), 256) AS hd_fx_fwsw_work,
    sha2(COALESCE(UPPER(TRIM(CAST(t_tran_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_tran_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_tran_id AS string))), ''), 256) AS hd_fx_fwsw_work_dynamic,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_fx_contract, t_deal_type, t_deal_date, t_ccy_bought, t_amt_bought, t_ccy_sold, t_amt_sold,
    t_spot_rate, t_fwd_rate, t_no_days, t_profit_loss, t_dly_amort, t_last_amort, t_base,
    t_value_date, t_lcy_equiv, t_lcy_dly_amort, t_lcy_last_amort, t_lcy_profit_loss,
    t_tran_date, t_tran_type, t_tran_id
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_vmbl_fx_fwsw_work')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_fx_fwsw_work] Insert business keys not yet in hub (ANTI JOIN on hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_fx_fwsw_work')
(fx_fwsw_work_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_vmbl_fx_fwsw_work QUALIFY ROW_NUMBER() OVER (PARTITION BY fx_fwsw_work_hashkey ORDER BY data_date) = 1)
SELECT d.fx_fwsw_work_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 't24__t24_vmbl_fx_fwsw_work'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_fx_fwsw_work') t
    ON t.fx_fwsw_work_hashkey = d.fx_fwsw_work_hashkey;

-- [sts_hub_fx_fwsw_work] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_fx_fwsw_work')
(fx_fwsw_work_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_vmbl_fx_fwsw_work
),
present_per_date AS (
    SELECT DISTINCT fx_fwsw_work_hashkey, source_event_date FROM tmp_t24_vmbl_fx_fwsw_work
),
full_timeline AS (
    SELECT DISTINCT h.fx_fwsw_work_hashkey, d.source_event_date,
           CASE WHEN p.fx_fwsw_work_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_fx_fwsw_work') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.fx_fwsw_work_hashkey = h.fx_fwsw_work_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT fx_fwsw_work_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY fx_fwsw_work_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT fx_fwsw_work_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_fx_fwsw_work')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_vmbl_fx_fwsw_work)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY fx_fwsw_work_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.fx_fwsw_work_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.fx_fwsw_work_hashkey = t.fx_fwsw_work_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.fx_fwsw_work_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.fx_fwsw_work_hashkey = t.fx_fwsw_work_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.fx_fwsw_work_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_fx_fwsw_work') t
    ON t.fx_fwsw_work_hashkey = sc.fx_fwsw_work_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_fx_fwsw_work] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_fx_fwsw_work')
(fx_fwsw_work_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_fx_contract, t_deal_type, t_deal_date, t_ccy_bought, t_amt_bought, t_ccy_sold, t_amt_sold,
 t_spot_rate, t_fwd_rate, t_no_days, t_profit_loss, t_dly_amort, t_last_amort, t_base,
 t_value_date, t_lcy_equiv, t_lcy_dly_amort, t_lcy_last_amort, t_lcy_profit_loss)
WITH last_known AS (
    SELECT fx_fwsw_work_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_fx_fwsw_work')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY fx_fwsw_work_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_fx_fwsw_work) OVER (PARTITION BY s.fx_fwsw_work_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_vmbl_fx_fwsw_work s
    LEFT JOIN last_known lk ON lk.fx_fwsw_work_hashkey = s.fx_fwsw_work_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_fx_fwsw_work != prev_hashdiff)
SELECT d.fx_fwsw_work_hashkey, d.hd_fx_fwsw_work, d.source_event_date, current_timestamp(), 't24__t24_vmbl_fx_fwsw_work',
       d.t_fx_contract, d.t_deal_type, d.t_deal_date, d.t_ccy_bought, d.t_amt_bought, d.t_ccy_sold, d.t_amt_sold,
       d.t_spot_rate, d.t_fwd_rate, d.t_no_days, d.t_profit_loss, d.t_dly_amort, d.t_last_amort, d.t_base,
       d.t_value_date, d.t_lcy_equiv, d.t_lcy_dly_amort, d.t_lcy_last_amort, d.t_lcy_profit_loss
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_fx_fwsw_work') t ON t.fx_fwsw_work_hashkey = d.fx_fwsw_work_hashkey AND t.source_event_date = d.source_event_date;

-- [sat_fx_fwsw_work_dynamic] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_fx_fwsw_work_dynamic')
(fx_fwsw_work_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_tran_date, t_tran_type, t_tran_id)
WITH last_known AS (
    SELECT fx_fwsw_work_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_fx_fwsw_work_dynamic')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY fx_fwsw_work_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_fx_fwsw_work_dynamic) OVER (PARTITION BY s.fx_fwsw_work_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_vmbl_fx_fwsw_work s
    LEFT JOIN last_known lk ON lk.fx_fwsw_work_hashkey = s.fx_fwsw_work_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_fx_fwsw_work_dynamic != prev_hashdiff)
SELECT d.fx_fwsw_work_hashkey, d.hd_fx_fwsw_work_dynamic, d.source_event_date, current_timestamp(), 't24__t24_vmbl_fx_fwsw_work',
       d.t_tran_date, d.t_tran_type, d.t_tran_id
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_fx_fwsw_work_dynamic') t ON t.fx_fwsw_work_hashkey = d.fx_fwsw_work_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_vmbl_fx_fwsw_work;
