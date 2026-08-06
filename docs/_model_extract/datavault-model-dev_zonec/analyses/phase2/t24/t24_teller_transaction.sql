-- Source: .t24.t24_teller_transaction
-- Target: ref_t24_teller_transaction
-- Range: 20250101 -> 20250131

DROP TEMPORARY TABLE IF EXISTS tmp_t24_teller_transaction; CREATE TEMPORARY TABLE tmp_t24_teller_transaction AS
SELECT
    sha2('teller_transaction' || CAST(id AS string), 256) AS Ref_hashkey,
    'teller_transaction' AS Ref_type,
    CAST(id AS string) AS Ref_code,
    CAST(T_DESC AS string) AS Ref_description,
    CAST(data_date AS string) AS DATA_DATE,
    CAST(T_SHORT_DESC AS string) AS T_SHORT_DESC,
    CAST(T_TRANSACTION_CODE_1 AS string) AS T_TRANSACTION_CODE_1,
    CAST(T_TRANSACTION_CODE_2 AS string) AS T_TRANSACTION_CODE_2,
    CAST(T_RECORD_STATUS AS string) AS T_RECORD_STATUS,
    CAST(T_CURR_NO AS string) AS T_CURR_NO,
    CAST(T_INPUTTER AS string) AS T_INPUTTER,
    CAST(T_DATE_TIME AS string) AS T_DATE_TIME,
    CAST(T_AUTHORISER AS string) AS T_AUTHORISER,
    CAST(T_CO_CODE AS string) AS T_CO_CODE,
    CAST(T_DEPT_CODE AS string) AS T_DEPT_CODE,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_short_desc AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_desc AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_transaction_code_1 AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_transaction_code_2 AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_dept_code AS string))), ''), 256) AS hashdiff_full,
    to_date(data_date, 'yyyyMMdd') AS source_event_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_teller_transaction')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [ref_t24_teller_transaction] Insert new records (ANTI JOIN on Ref_hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_teller_transaction')
(Ref_hashkey, Ref_type, Ref_code, Ref_description, DATA_DATE,
 T_SHORT_DESC, T_TRANSACTION_CODE_1, T_TRANSACTION_CODE_2, T_RECORD_STATUS, T_CURR_NO,
 T_INPUTTER, T_DATE_TIME, T_AUTHORISER, T_CO_CODE, T_DEPT_CODE, hashdiff_full, source_event_date, load_timestamp, Record_source)
WITH deduped AS (SELECT * FROM tmp_t24_teller_transaction QUALIFY ROW_NUMBER() OVER (PARTITION BY Ref_hashkey, hashdiff_full ORDER BY DATA_DATE) = 1)
SELECT d.Ref_hashkey, d.Ref_type, d.Ref_code, d.Ref_description, d.DATA_DATE,
    d.T_SHORT_DESC, d.T_TRANSACTION_CODE_1, d.T_TRANSACTION_CODE_2, d.T_RECORD_STATUS, d.T_CURR_NO,
    d.T_INPUTTER, d.T_DATE_TIME, d.T_AUTHORISER, d.T_CO_CODE, d.T_DEPT_CODE, d.hashdiff_full, d.source_event_date, current_timestamp(), 't24__t24_teller_transaction'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_teller_transaction') t
    ON t.Ref_hashkey = d.Ref_hashkey AND t.hashdiff_full = d.hashdiff_full;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_teller_transaction;
