-- Source: .t24.t24_auto_name
-- Target: ref_t24_auto_name
-- Range: 20250101 -> 20250131

DROP TEMPORARY TABLE IF EXISTS tmp_t24_auto_name; CREATE TEMPORARY TABLE tmp_t24_auto_name AS
SELECT
    sha2('auto_name' || CAST(id AS string), 256) AS Ref_hashkey,
    'auto_name' AS Ref_type,
    CAST(id AS string) AS Ref_code,
    CAST(T_NAME AS string) AS Ref_description,
    CAST(data_date AS string) AS DATA_DATE,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' || COALESCE(UPPER(TRIM(CAST(T_NAME AS string))), ''), 256) AS hashdiff_full,
    to_date(data_date, 'yyyyMMdd') AS source_event_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_auto_name')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [ref_t24_auto_name] Insert new records (ANTI JOIN on Ref_hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_auto_name')
(Ref_hashkey, Ref_type, Ref_code, Ref_description, DATA_DATE, hashdiff_full, source_event_date, load_timestamp, Record_source)
WITH deduped AS (SELECT * FROM tmp_t24_auto_name QUALIFY ROW_NUMBER() OVER (PARTITION BY Ref_hashkey, hashdiff_full ORDER BY DATA_DATE) = 1)
SELECT d.Ref_hashkey, d.Ref_type, d.Ref_code, d.Ref_description, d.DATA_DATE, d.hashdiff_full, d.source_event_date, current_timestamp(), 't24__t24_auto_name'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_auto_name') t
    ON t.Ref_hashkey = d.Ref_hashkey AND t.hashdiff_full = d.hashdiff_full;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_auto_name;
