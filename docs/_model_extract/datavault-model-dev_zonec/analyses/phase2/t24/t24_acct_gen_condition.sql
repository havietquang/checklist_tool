-- Source: .t24.t24_acct_gen_condition
-- Target: ref_t24_acct_gen_condition
-- Range: 20250101 -> 20250131

DROP TEMPORARY TABLE IF EXISTS tmp_t24_acct_gen_condition; CREATE TEMPORARY TABLE tmp_t24_acct_gen_condition AS
SELECT
    sha2('acct_gen_condition' || CAST(ID AS string), 256) AS Ref_hashkey,
    'acct_gen_condition' AS Ref_type,
    CAST(ID AS string) AS Ref_code,
    CAST(T_DESCRIPTION AS string) AS Ref_description,
    CAST(data_date AS string) AS DATA_DATE,
    CAST(T_ITEM AS string) AS T_ITEM,
    CAST(T_PRIORITY AS string) AS T_PRIORITY,
    CAST(T_VALUE AS string) AS T_VALUE,
    CAST(T_MULTIVALUE AS string) AS T_MULTIVALUE,
    CAST(T_CO_CODE AS string) AS T_CO_CODE,
    CAST(T_INPUTTER AS string) AS T_INPUTTER,
    CAST(T_DATE_TIME AS string) AS T_DATE_TIME,
    CAST(T_AUTHORISER AS string) AS T_AUTHORISER,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_item AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_priority AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_value AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_multivalue AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), ''), 256) AS hashdiff_full,
    to_date(data_date, 'yyyyMMdd') AS source_event_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_acct_gen_condition')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND ID IS NOT NULL;

-- [ref_t24_acct_gen_condition] Insert new records (ANTI JOIN on Ref_hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_acct_gen_condition')
(Ref_hashkey, Ref_type, Ref_code, Ref_description, DATA_DATE,
 T_ITEM, T_PRIORITY, T_VALUE, T_MULTIVALUE, T_CO_CODE, T_INPUTTER, T_DATE_TIME, T_AUTHORISER,
 hashdiff_full, source_event_date, load_timestamp, Record_source)
WITH deduped AS (SELECT * FROM tmp_t24_acct_gen_condition QUALIFY ROW_NUMBER() OVER (PARTITION BY Ref_hashkey, hashdiff_full ORDER BY DATA_DATE) = 1)
SELECT d.Ref_hashkey, d.Ref_type, d.Ref_code, d.Ref_description, d.DATA_DATE,
    d.T_ITEM, d.T_PRIORITY, d.T_VALUE, d.T_MULTIVALUE, d.T_CO_CODE, d.T_INPUTTER, d.T_DATE_TIME, d.T_AUTHORISER,
    d.hashdiff_full, d.source_event_date, current_timestamp(), 't24__t24_acct_gen_condition'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_acct_gen_condition') t
    ON t.Ref_hashkey = d.Ref_hashkey AND t.hashdiff_full = d.hashdiff_full;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_acct_gen_condition;
