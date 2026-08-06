DROP TEMPORARY TABLE IF EXISTS src_ows_add_data;
CREATE TEMPORARY TABLE src_ows_add_data AS SELECT * FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_add_data');
-- Source: way4.ows_add_data (raw: way4.ows_add_data) | Target: ref_way4_ows_add_data (phase2)
-- Reference full load | Ref_code = cast(id as string) | filter: AMND_STATE  = 'A'
-- hashdiff_full = sha2 toan bo cot nguon (giong macro stage) | source_event_date = start_date
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_way4_ows_add_data')
(Ref_hashkey, Ref_type, Ref_code, Ref_description, AMND_STATE, AMND_DATE, AMND_OFFICER, AMND_PREV, ID, ADD_DATA_COL__ID, FOR_ID, ADD_DATA_TAB, VAL, PARTITION_KEY, DATA_DATE, hashdiff_full, source_event_date, Record_source, load_timestamp)
WITH base AS (
    SELECT
        sha2(('w4_ows_add_data' || cast(id as string)), 256) AS Ref_hashkey,
        'w4_ows_add_data' AS Ref_type,
        cast(id as string) AS Ref_code,
        cast(VAL as string) AS Ref_description,
        AMND_STATE,
        AMND_DATE,
        AMND_OFFICER,
        AMND_PREV,
        ID,
        ADD_DATA_COL__ID,
        FOR_ID,
        ADD_DATA_TAB,
        VAL,
        PARTITION_KEY,
        DATA_DATE,
        sha2(COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(add_data_col__id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(for_id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(add_data_tab AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(val AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(partition_key AS string))), ''), 256) AS hashdiff_full,
        to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_add_data' as string) AS Record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM src_ows_add_data
    WHERE AMND_STATE  = 'A' AND data_date BETWEEN {{start_date}} AND {{end_date}}
),
dedup AS (
    SELECT * FROM base
    WHERE Ref_hashkey IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY Ref_hashkey ORDER BY source_event_date DESC) = 1
)
SELECT d.Ref_hashkey, d.Ref_type, d.Ref_code, d.Ref_description, d.AMND_STATE, d.AMND_DATE, d.AMND_OFFICER, d.AMND_PREV, d.ID, d.ADD_DATA_COL__ID, d.FOR_ID, d.ADD_DATA_TAB, d.VAL, d.PARTITION_KEY, d.DATA_DATE, d.hashdiff_full, d.source_event_date, d.Record_source, d.load_timestamp
FROM dedup d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_way4_ows_add_data') t
    ON t.Ref_hashkey = d.Ref_hashkey;
