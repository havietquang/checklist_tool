-- Source: .t24.t24_ocbh_coll_bpm_store
-- Target: :catalog_cleaned.raw_vault
--   hub_coll_bpm_store, sts_hub_coll_bpm_store, sat_coll_bpm_store
--   link_coll_bpm_store_collateral
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_ocbh_coll_bpm_store; CREATE TEMPORARY TABLE tmp_t24_ocbh_coll_bpm_store AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS coll_bpm_store_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_txn_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_collateral_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_bpm_trans_id AS string))), ''), 256) AS hd_coll_bpm_store,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_collateral_id AS string))), ''), 256) AS link_coll_bpm_store_collateral_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_collateral_id AS string))), ''), 256) AS collateral_hashkey,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_txn_status, t_collateral_id, t_bpm_trans_id
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_ocbh_coll_bpm_store')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_coll_bpm_store] Insert business keys not yet in hub (ANTI JOIN on hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_coll_bpm_store')
(coll_bpm_store_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_ocbh_coll_bpm_store QUALIFY ROW_NUMBER() OVER (PARTITION BY coll_bpm_store_hashkey ORDER BY data_date) = 1)
SELECT d.coll_bpm_store_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 't24__t24_ocbh_coll_bpm_store'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_coll_bpm_store') t
    ON t.coll_bpm_store_hashkey = d.coll_bpm_store_hashkey;

-- [sts_hub_coll_bpm_store] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_coll_bpm_store')
(coll_bpm_store_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_ocbh_coll_bpm_store
),
present_per_date AS (
    SELECT DISTINCT coll_bpm_store_hashkey, source_event_date FROM tmp_t24_ocbh_coll_bpm_store
),
full_timeline AS (
    SELECT DISTINCT h.coll_bpm_store_hashkey, d.source_event_date,
           CASE WHEN p.coll_bpm_store_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_coll_bpm_store') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.coll_bpm_store_hashkey = h.coll_bpm_store_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT coll_bpm_store_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY coll_bpm_store_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT coll_bpm_store_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_coll_bpm_store')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_ocbh_coll_bpm_store)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY coll_bpm_store_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.coll_bpm_store_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.coll_bpm_store_hashkey = t.coll_bpm_store_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.coll_bpm_store_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.coll_bpm_store_hashkey = t.coll_bpm_store_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.coll_bpm_store_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_coll_bpm_store') t
    ON t.coll_bpm_store_hashkey = sc.coll_bpm_store_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_coll_bpm_store] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_coll_bpm_store')
(coll_bpm_store_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_txn_status, t_collateral_id, t_bpm_trans_id)
WITH last_known AS (
    SELECT coll_bpm_store_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_coll_bpm_store')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY coll_bpm_store_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_coll_bpm_store) OVER (PARTITION BY s.coll_bpm_store_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_ocbh_coll_bpm_store s
    LEFT JOIN last_known lk ON lk.coll_bpm_store_hashkey = s.coll_bpm_store_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_coll_bpm_store != prev_hashdiff)
SELECT d.coll_bpm_store_hashkey, d.hd_coll_bpm_store, d.source_event_date, current_timestamp(), 't24__t24_ocbh_coll_bpm_store',
       d.t_txn_status, d.t_collateral_id, d.t_bpm_trans_id
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_coll_bpm_store') t ON t.coll_bpm_store_hashkey = d.coll_bpm_store_hashkey AND t.source_event_date = d.source_event_date;

-- [link_coll_bpm_store_collateral] Insert new relationships (ANTI JOIN on link hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_coll_bpm_store_collateral')
(link_coll_bpm_store_collateral_hashkey, coll_bpm_store_hashkey, collateral_hashkey, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_ocbh_coll_bpm_store WHERE t_collateral_id IS NOT NULL QUALIFY ROW_NUMBER() OVER (PARTITION BY link_coll_bpm_store_collateral_hashkey ORDER BY data_date) = 1)
SELECT d.link_coll_bpm_store_collateral_hashkey, d.coll_bpm_store_hashkey, d.collateral_hashkey, d.source_event_date, current_timestamp(), 't24__t24_ocbh_coll_bpm_store'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_coll_bpm_store_collateral') t
    ON t.link_coll_bpm_store_collateral_hashkey = d.link_coll_bpm_store_collateral_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_ocbh_coll_bpm_store;
