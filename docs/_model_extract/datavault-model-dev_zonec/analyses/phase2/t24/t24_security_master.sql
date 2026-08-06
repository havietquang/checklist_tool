-- Source: .t24.t24_security_master
-- Target: :catalog_cleaned.raw_vault
--   sat_security_information (phase2)
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_security_master; CREATE TEMPORARY TABLE tmp_t24_security_master AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS security_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_company_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_descript AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_short_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_mnemonic AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_stock_exchange AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_issue_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_maturity_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_alt_security_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_alt_security_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_company_domicile AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_set_up_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_group_partner AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_business_pp AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_bss_detail_pp AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_sc_ind_internal AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_trading_units AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_margin_control AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ftp_description AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_limit_ref AS string))), ''), 256) AS hd_security_information,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_company_name, t_descript, t_short_name, t_mnemonic, t_stock_exchange, t_issue_date, t_maturity_date,
    t_alt_security_id, t_alt_security_no, t_company_domicile, t_set_up_date, t_group_partner,
    t_business_pp, t_bss_detail_pp, t_sc_ind_internal, t_trading_units, t_margin_control,
    t_ftp_description, t_limit_ref
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_security_master')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [sat_security_information] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_security_information')
(security_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_company_name, t_descript, t_short_name, t_mnemonic, t_stock_exchange, t_issue_date, t_maturity_date,
 t_alt_security_id, t_alt_security_no, t_company_domicile, t_set_up_date, t_group_partner,
 t_business_pp, t_bss_detail_pp, t_sc_ind_internal, t_trading_units, t_margin_control,
 t_ftp_description, t_limit_ref)
WITH last_known AS (
    SELECT security_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_security_information')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY security_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_security_information) OVER (PARTITION BY s.security_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_security_master s
    LEFT JOIN last_known lk ON lk.security_hashkey = s.security_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_security_information != prev_hashdiff)
SELECT d.security_hashkey, d.hd_security_information, d.source_event_date, current_timestamp(), 't24__t24_security_master',
       d.t_company_name, d.t_descript, d.t_short_name, d.t_mnemonic, d.t_stock_exchange, d.t_issue_date, d.t_maturity_date,
       d.t_alt_security_id, d.t_alt_security_no, d.t_company_domicile, d.t_set_up_date, d.t_group_partner,
       d.t_business_pp, d.t_bss_detail_pp, d.t_sc_ind_internal, d.t_trading_units, d.t_margin_control,
       d.t_ftp_description, d.t_limit_ref
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_security_information') t ON t.security_hashkey = d.security_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_security_master;
