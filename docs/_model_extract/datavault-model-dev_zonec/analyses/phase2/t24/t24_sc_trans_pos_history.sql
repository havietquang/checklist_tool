-- Source: .t24.t24_sc_trans_pos_history
-- Target: :catalog_cleaned.raw_vault
--   hub_sc_trading_position, sts_hub_sc_trans_pos_history, sat_sc_trans_pos_history
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_sc_trans_pos_history; CREATE TEMPORARY TABLE tmp_t24_sc_trans_pos_history AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS sc_trading_position_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_security_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_curr_per_st_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_sop_position AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_sop_avg_price AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_sop_cost_position AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_close_bus_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cob_position AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cob_avg_price AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cob_cost_position AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ptd_real_pl_posted AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ptd_real_pl_calc AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ptd_da_calc AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_trade_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pos_date_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_trade_ref AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_trans_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_nominal AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_clean_price AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_consid AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_accr_interest AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_value_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_trd_disc_accr AS string))), ''), 256) AS hd_sc_trans_pos_history,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_security_ccy, t_curr_per_st_date, t_sop_position, t_sop_avg_price, t_sop_cost_position,
    t_close_bus_date, t_cob_position, t_cob_avg_price, t_cob_cost_position,
    t_ptd_real_pl_posted, t_ptd_real_pl_calc, t_ptd_da_calc, t_trade_date, t_pos_date_time,
    t_trade_ref, t_trans_type, t_nominal, t_clean_price, t_consid, t_accr_interest,
    t_value_date, t_trd_disc_accr
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_sc_trans_pos_history')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_sc_trading_position] Insert business keys not yet in hub (ANTI JOIN on hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_sc_trading_position')
(sc_trading_position_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_sc_trans_pos_history QUALIFY ROW_NUMBER() OVER (PARTITION BY sc_trading_position_hashkey ORDER BY data_date) = 1)
SELECT d.sc_trading_position_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 't24__t24_sc_trans_pos_history'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_sc_trading_position') t
    ON t.sc_trading_position_hashkey = d.sc_trading_position_hashkey;

-- [sts_hub_sc_trans_pos_history] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_sc_trans_pos_history')
(sc_trading_position_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_sc_trans_pos_history
),
present_per_date AS (
    SELECT DISTINCT sc_trading_position_hashkey, source_event_date FROM tmp_t24_sc_trans_pos_history
),
full_timeline AS (
    SELECT DISTINCT h.sc_trading_position_hashkey, d.source_event_date,
           CASE WHEN p.sc_trading_position_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_sc_trading_position') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.sc_trading_position_hashkey = h.sc_trading_position_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT sc_trading_position_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY sc_trading_position_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT sc_trading_position_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_sc_trans_pos_history')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_sc_trans_pos_history)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY sc_trading_position_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.sc_trading_position_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.sc_trading_position_hashkey = t.sc_trading_position_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.sc_trading_position_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.sc_trading_position_hashkey = t.sc_trading_position_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.sc_trading_position_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_sc_trans_pos_history') t
    ON t.sc_trading_position_hashkey = sc.sc_trading_position_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_sc_trans_pos_history] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_sc_trans_pos_history')
(sc_trading_position_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_security_ccy, t_curr_per_st_date, t_sop_position, t_sop_avg_price, t_sop_cost_position,
 t_close_bus_date, t_cob_position, t_cob_avg_price, t_cob_cost_position,
 t_ptd_real_pl_posted, t_ptd_real_pl_calc, t_ptd_da_calc, t_trade_date, t_pos_date_time,
 t_trade_ref, t_trans_type, t_nominal, t_clean_price, t_consid, t_accr_interest,
 t_value_date, t_trd_disc_accr)
WITH last_known AS (
    SELECT sc_trading_position_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_sc_trans_pos_history')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY sc_trading_position_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_sc_trans_pos_history) OVER (PARTITION BY s.sc_trading_position_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_sc_trans_pos_history s
    LEFT JOIN last_known lk ON lk.sc_trading_position_hashkey = s.sc_trading_position_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_sc_trans_pos_history != prev_hashdiff)
SELECT d.sc_trading_position_hashkey, d.hd_sc_trans_pos_history, d.source_event_date, current_timestamp(), 't24__t24_sc_trans_pos_history',
       d.t_security_ccy, d.t_curr_per_st_date, d.t_sop_position, d.t_sop_avg_price, d.t_sop_cost_position,
       d.t_close_bus_date, d.t_cob_position, d.t_cob_avg_price, d.t_cob_cost_position,
       d.t_ptd_real_pl_posted, d.t_ptd_real_pl_calc, d.t_ptd_da_calc, d.t_trade_date, d.t_pos_date_time,
       d.t_trade_ref, d.t_trans_type, d.t_nominal, d.t_clean_price, d.t_consid, d.t_accr_interest,
       d.t_value_date, d.t_trd_disc_accr
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_sc_trans_pos_history') t ON t.sc_trading_position_hashkey = d.sc_trading_position_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_sc_trans_pos_history;
