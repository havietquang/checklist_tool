-- Source: .t24.t24_prod_package_cb
-- Target: ref_t24_prod_package_cb
-- Range: 20250101 -> 20250131

DROP TEMPORARY TABLE IF EXISTS tmp_t24_prod_package_cb; CREATE TEMPORARY TABLE tmp_t24_prod_package_cb AS
SELECT
    sha2('prod_package_cb' || CAST(id AS string), 256) AS Ref_hashkey,
    'prod_package_cb' AS Ref_type,
    CAST(id AS string) AS Ref_code,
    CAST(T_PACKAGE_NAME AS string) AS Ref_description,
    CAST(data_date AS string) AS DATA_DATE,
    CAST(T_AC_MANAGE_FEE_PER AS string) AS T_AC_MANAGE_FEE_PER,
    CAST(T_EXT_FT_FEE_PER AS string) AS T_EXT_FT_FEE_PER,
    CAST(T_IB_FEE_PER AS string) AS T_IB_FEE_PER,
    CAST(T_TAX_FEE_PER AS string) AS T_TAX_FEE_PER,
    CAST(T_SMS_FEE_PER AS string) AS T_SMS_FEE_PER,
    CAST(T_RECORD_STATUS AS string) AS T_RECORD_STATUS,
    CAST(T_CURR_NO AS string) AS T_CURR_NO,
    CAST(T_INPUTTER AS string) AS T_INPUTTER,
    CAST(T_DATE_TIME AS string) AS T_DATE_TIME,
    CAST(T_AUTHORISER AS string) AS T_AUTHORISER,
    CAST(T_CO_CODE AS string) AS T_CO_CODE,
    CAST(T_DEPT_CODE AS string) AS T_DEPT_CODE,
    CAST(T_PACKAGE_FDATE AS string) AS T_PACKAGE_FDATE,
    CAST(T_PACKAGE_TDATE AS string) AS T_PACKAGE_TDATE,
    CAST(T_AC_MANAGE_FEE_TERM AS string) AS T_AC_MANAGE_FEE_TERM,
    CAST(T_EXT_FT_FEE_TERM AS string) AS T_EXT_FT_FEE_TERM,
    CAST(T_IB_FEE_TERM AS string) AS T_IB_FEE_TERM,
    CAST(T_TAX_FEE_TERM AS string) AS T_TAX_FEE_TERM,
    CAST(T_SMS_FEE_TERM AS string) AS T_SMS_FEE_TERM,
    CAST(T_AC_MIN_AVR_BALANCE AS string) AS T_AC_MIN_AVR_BALANCE,
    CAST(T_BATCH_FT_FEE_PER AS string) AS T_BATCH_FT_FEE_PER,
    CAST(T_BATCH_FT_FEE_TERM AS string) AS T_BATCH_FT_FEE_TERM,
    CAST(T_FT_8S_FEE_PER AS string) AS T_FT_8S_FEE_PER,
    CAST(T_FT_8S_FEE_TERM AS string) AS T_FT_8S_FEE_TERM,
    CAST(T_EXT_FO_FEE_PER AS string) AS T_EXT_FO_FEE_PER,
    CAST(T_EXT_FO_FEE_TERM AS string) AS T_EXT_FO_FEE_TERM,
    CAST(T_AVR_BALANCE_FROM AS string) AS T_AVR_BALANCE_FROM,
    CAST(T_AVR_BALANCE_TO AS string) AS T_AVR_BALANCE_TO,
    CAST(T_AC_MANAGE_FEE AS string) AS T_AC_MANAGE_FEE,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_package_name AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_ac_manage_fee_per AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_ext_ft_fee_per AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_ib_fee_per AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_tax_fee_per AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_sms_fee_per AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_dept_code AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_package_fdate AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_package_tdate AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_ac_manage_fee_term AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_ext_ft_fee_term AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_ib_fee_term AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_tax_fee_term AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_sms_fee_term AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_ac_min_avr_balance AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_batch_ft_fee_per AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_batch_ft_fee_term AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_ft_8s_fee_per AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_ft_8s_fee_term AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_ext_fo_fee_per AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_ext_fo_fee_term AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_avr_balance_from AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_avr_balance_to AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_ac_manage_fee AS string))), ''), 256) AS hashdiff_full,
    to_date(data_date, 'yyyyMMdd') AS source_event_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_prod_package_cb')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [ref_t24_prod_package_cb] Insert new records (ANTI JOIN on Ref_hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_prod_package_cb')
(Ref_hashkey, Ref_type, Ref_code, Ref_description, DATA_DATE,
 T_AC_MANAGE_FEE_PER, T_EXT_FT_FEE_PER, T_IB_FEE_PER, T_TAX_FEE_PER, T_SMS_FEE_PER,
 T_RECORD_STATUS, T_CURR_NO, T_INPUTTER, T_DATE_TIME, T_AUTHORISER, T_CO_CODE, T_DEPT_CODE,
 T_PACKAGE_FDATE, T_PACKAGE_TDATE, T_AC_MANAGE_FEE_TERM, T_EXT_FT_FEE_TERM, T_IB_FEE_TERM,
 T_TAX_FEE_TERM, T_SMS_FEE_TERM, T_AC_MIN_AVR_BALANCE, T_BATCH_FT_FEE_PER, T_BATCH_FT_FEE_TERM,
 T_FT_8S_FEE_PER, T_FT_8S_FEE_TERM, T_EXT_FO_FEE_PER, T_EXT_FO_FEE_TERM,
 T_AVR_BALANCE_FROM, T_AVR_BALANCE_TO, T_AC_MANAGE_FEE, hashdiff_full, source_event_date, load_timestamp, Record_source)
WITH deduped AS (SELECT * FROM tmp_t24_prod_package_cb QUALIFY ROW_NUMBER() OVER (PARTITION BY Ref_hashkey, hashdiff_full ORDER BY DATA_DATE) = 1)
SELECT d.Ref_hashkey, d.Ref_type, d.Ref_code, d.Ref_description, d.DATA_DATE,
    d.T_AC_MANAGE_FEE_PER, d.T_EXT_FT_FEE_PER, d.T_IB_FEE_PER, d.T_TAX_FEE_PER, d.T_SMS_FEE_PER,
    d.T_RECORD_STATUS, d.T_CURR_NO, d.T_INPUTTER, d.T_DATE_TIME, d.T_AUTHORISER, d.T_CO_CODE, d.T_DEPT_CODE,
    d.T_PACKAGE_FDATE, d.T_PACKAGE_TDATE, d.T_AC_MANAGE_FEE_TERM, d.T_EXT_FT_FEE_TERM, d.T_IB_FEE_TERM,
    d.T_TAX_FEE_TERM, d.T_SMS_FEE_TERM, d.T_AC_MIN_AVR_BALANCE, d.T_BATCH_FT_FEE_PER, d.T_BATCH_FT_FEE_TERM,
    d.T_FT_8S_FEE_PER, d.T_FT_8S_FEE_TERM, d.T_EXT_FO_FEE_PER, d.T_EXT_FO_FEE_TERM,
    d.T_AVR_BALANCE_FROM, d.T_AVR_BALANCE_TO, d.T_AC_MANAGE_FEE, d.hashdiff_full, d.source_event_date, current_timestamp(), 't24__t24_prod_package_cb'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_prod_package_cb') t
    ON t.Ref_hashkey = d.Ref_hashkey AND t.hashdiff_full = d.hashdiff_full;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_prod_package_cb;
