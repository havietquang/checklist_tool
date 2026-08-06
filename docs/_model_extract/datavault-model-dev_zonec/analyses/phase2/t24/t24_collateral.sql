-- Source: .t24.t24_collateral
-- Target: :catalog_cleaned.raw_vault
--   sat_collateral_information (phase2)
--   link_collateral_az_account (phase2, filter: t_application_id NOT LIKE 'LD%')
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_collateral; CREATE TEMPORARY TABLE tmp_t24_collateral AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS collateral_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_application_id AS string))), ''), 256) AS link_collateral_az_account_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_application_id AS string))), ''), 256) AS account_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_collateral_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_collateral_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_coll_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_expiry_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_value_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ocb_co_note AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_notes AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_in_cluster AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_borrow_purpose AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ld_cust_group AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ocb_start_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ocb_end_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(T_CURRENCY AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_application_id AS string))), ''), 256) AS hd_collateral_information,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id, t_application_id,
    t_collateral_type, t_description, t_collateral_code, t_coll_status, t_expiry_date, t_value_date,
    t_ocb_co_note, t_notes, t_in_cluster, t_borrow_purpose, t_ld_cust_group, t_ocb_start_date, t_ocb_end_date,
    t_inputter, t_date_time, t_authoriser, T_CURRENCY
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_collateral')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [sat_collateral_information] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_collateral_information')
(collateral_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_collateral_type, t_description, t_collateral_code, t_coll_status, t_expiry_date, t_value_date,
 t_ocb_co_note, t_notes, t_in_cluster, t_borrow_purpose, t_ld_cust_group, t_ocb_start_date, t_ocb_end_date,
 t_inputter, t_date_time, t_authoriser, T_CURRENCY, t_application_id)
WITH last_known AS (
    SELECT collateral_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_collateral_information')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY collateral_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_collateral_information) OVER (PARTITION BY s.collateral_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_collateral s
    LEFT JOIN last_known lk ON lk.collateral_hashkey = s.collateral_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_collateral_information != prev_hashdiff)
SELECT d.collateral_hashkey, d.hd_collateral_information, d.source_event_date, current_timestamp(), 't24__t24_collateral',
       d.t_collateral_type, d.t_description, d.t_collateral_code, d.t_coll_status, d.t_expiry_date, d.t_value_date,
       d.t_ocb_co_note, d.t_notes, d.t_in_cluster, d.t_borrow_purpose, d.t_ld_cust_group, d.t_ocb_start_date, d.t_ocb_end_date,
       d.t_inputter, d.t_date_time, d.t_authoriser, d.T_CURRENCY, d.t_application_id
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_collateral_information') t ON t.collateral_hashkey = d.collateral_hashkey AND t.source_event_date = d.source_event_date;

-- [link_collateral_az_account] Insert new relationships (ANTI JOIN on link hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_collateral_az_account')
(link_collateral_az_account_hashkey, collateral_hashkey, account_hashkey, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_collateral WHERE t_application_id IS NOT NULL AND t_application_id NOT LIKE 'LD%' QUALIFY ROW_NUMBER() OVER (PARTITION BY link_collateral_az_account_hashkey ORDER BY data_date) = 1)
SELECT d.link_collateral_az_account_hashkey, d.collateral_hashkey, d.account_hashkey, d.source_event_date, current_timestamp(), 't24__t24_collateral'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_collateral_az_account') t
    ON t.link_collateral_az_account_hashkey = d.link_collateral_az_account_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_collateral;
