-- Source: .t24.t24_sc_block_sec_pos
-- Target: :catalog_cleaned.raw_vault
--   hub_security_block, sts_hub_security_block, sat_security_block
--   link_security_block_security
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_sc_block_sec_pos; CREATE TEMPORARY TABLE tmp_t24_sc_block_sec_pos AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS security_block_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_action_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_addition_info AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_block_eff_from AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_blocked_until AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_curr_amt_blocked AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_diary_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_eff_from_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_eff_to_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_entitlement AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_interest_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_maturity_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_new_amt_blocked AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_new_block_amt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_sec_depot AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_securities_account AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_security_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_sub_account AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_trans_reference AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_transaction_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_product AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_notification_msg AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ocb_sc_pp_gtcg AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ocb_sc_co_gtcg AS string))), ''), 256) AS hd_security_block,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_security_code AS string))), ''), 256) AS link_security_block_security_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_security_code AS string))), ''), 256) AS security_hashkey,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_action_date, t_addition_info, t_block_eff_from, t_blocked_until, t_curr_amt_blocked, t_diary_id,
    t_eff_from_date, t_eff_to_date, t_entitlement, t_interest_rate, t_maturity_date, t_new_amt_blocked,
    t_new_block_amt, t_sec_depot, t_securities_account, t_security_code, t_sub_account, t_trans_reference,
    t_transaction_type, t_product, t_notification_msg, t_inputter, t_date_time, t_authoriser, t_co_code,
    t_ocb_sc_pp_gtcg, t_ocb_sc_co_gtcg
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_sc_block_sec_pos')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_security_block] Insert business keys not yet in hub (ANTI JOIN on hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_security_block')
(security_block_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_sc_block_sec_pos QUALIFY ROW_NUMBER() OVER (PARTITION BY security_block_hashkey ORDER BY data_date) = 1)
SELECT d.security_block_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 't24__t24_sc_block_sec_pos'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_security_block') t
    ON t.security_block_hashkey = d.security_block_hashkey;

-- [sts_hub_security_block] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_security_block')
(security_block_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_sc_block_sec_pos
),
present_per_date AS (
    SELECT DISTINCT security_block_hashkey, source_event_date FROM tmp_t24_sc_block_sec_pos
),
full_timeline AS (
    SELECT DISTINCT h.security_block_hashkey, d.source_event_date,
           CASE WHEN p.security_block_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_security_block') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.security_block_hashkey = h.security_block_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT security_block_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY security_block_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT security_block_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_security_block')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_sc_block_sec_pos)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY security_block_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.security_block_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.security_block_hashkey = t.security_block_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.security_block_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.security_block_hashkey = t.security_block_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.security_block_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_security_block') t
    ON t.security_block_hashkey = sc.security_block_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_security_block] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_security_block')
(security_block_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_action_date, t_addition_info, t_block_eff_from, t_blocked_until, t_curr_amt_blocked, t_diary_id,
 t_eff_from_date, t_eff_to_date, t_entitlement, t_interest_rate, t_maturity_date, t_new_amt_blocked,
 t_new_block_amt, t_sec_depot, t_securities_account, t_security_code, t_sub_account, t_trans_reference,
 t_transaction_type, t_product, t_notification_msg, t_inputter, t_date_time, t_authoriser, t_co_code,
 t_ocb_sc_pp_gtcg, t_ocb_sc_co_gtcg)
WITH last_known AS (
    SELECT security_block_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_security_block')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY security_block_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_security_block) OVER (PARTITION BY s.security_block_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_sc_block_sec_pos s
    LEFT JOIN last_known lk ON lk.security_block_hashkey = s.security_block_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_security_block != prev_hashdiff)
SELECT d.security_block_hashkey, d.hd_security_block, d.source_event_date, current_timestamp(), 't24__t24_sc_block_sec_pos',
       d.t_action_date, d.t_addition_info, d.t_block_eff_from, d.t_blocked_until, d.t_curr_amt_blocked, d.t_diary_id,
       d.t_eff_from_date, d.t_eff_to_date, d.t_entitlement, d.t_interest_rate, d.t_maturity_date, d.t_new_amt_blocked,
       d.t_new_block_amt, d.t_sec_depot, d.t_securities_account, d.t_security_code, d.t_sub_account, d.t_trans_reference,
       d.t_transaction_type, d.t_product, d.t_notification_msg, d.t_inputter, d.t_date_time, d.t_authoriser, d.t_co_code,
       d.t_ocb_sc_pp_gtcg, d.t_ocb_sc_co_gtcg
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_security_block') t ON t.security_block_hashkey = d.security_block_hashkey AND t.source_event_date = d.source_event_date;

-- [link_security_block_security] Insert new relationships (ANTI JOIN on link hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_security_block_security')
(link_security_block_security_hashkey, security_block_hashkey, security_hashkey, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_sc_block_sec_pos WHERE t_security_code IS NOT NULL QUALIFY ROW_NUMBER() OVER (PARTITION BY link_security_block_security_hashkey ORDER BY data_date) = 1)
SELECT d.link_security_block_security_hashkey, d.security_block_hashkey, d.security_hashkey, d.source_event_date, current_timestamp(), 't24__t24_sc_block_sec_pos'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_security_block_security') t
    ON t.link_security_block_security_hashkey = d.link_security_block_security_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_sc_block_sec_pos;
