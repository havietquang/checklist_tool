DROP TEMPORARY TABLE IF EXISTS src_ows_td_auth_type;
CREATE TEMPORARY TABLE src_ows_td_auth_type AS SELECT * FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_td_auth_type');
-- Source: way4.ows_td_auth_type (raw: way4.ows_td_auth_type) | Target: ref_way4_ows_td_auth_type (phase2)
-- Reference full load | Ref_code = concat_ws('', cast(id as string), cast(code as string)) | filter: AMND_STATE  = 'A'
-- hashdiff_full = sha2 toan bo cot nguon (giong macro stage) | source_event_date = start_date
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_way4_ows_td_auth_type')
(Ref_hashkey, Ref_type, Ref_code, Ref_description, AMND_DATE, AMND_OFFICER, AMND_STATE, AMND_PREV, ID, AUTH_TYPE_CAT, NAME, CODE, IDT_REQUIRED, VERSION_IDT, BASE_TYPE, IS_READY, hashdiff_full, source_event_date, Record_source, load_timestamp)
WITH base AS (
    SELECT
        sha2(('w4_ows_td_auth_type' || concat_ws('', cast(id as string), cast(code as string))), 256) AS Ref_hashkey,
        'w4_ows_td_auth_type' AS Ref_type,
        concat_ws('', cast(id as string), cast(code as string)) AS Ref_code,
        cast(name as string) AS Ref_description,
        AMND_DATE,
        AMND_OFFICER,
        AMND_STATE,
        AMND_PREV,
        ID,
        AUTH_TYPE_CAT,
        NAME,
        CODE,
        IDT_REQUIRED,
        VERSION_IDT,
        BASE_TYPE,
        IS_READY,
        sha2(COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(auth_type_cat AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(idt_required AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(version_idt AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(base_type AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(is_ready AS string))), ''), 256) AS hashdiff_full,
        to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_td_auth_type' as string) AS Record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM src_ows_td_auth_type
    WHERE AMND_STATE  = 'A'
),
dedup AS (
    SELECT * FROM base
    WHERE Ref_hashkey IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY Ref_hashkey ORDER BY source_event_date DESC) = 1
)
SELECT d.Ref_hashkey, d.Ref_type, d.Ref_code, d.Ref_description, d.AMND_DATE, d.AMND_OFFICER, d.AMND_STATE, d.AMND_PREV, d.ID, d.AUTH_TYPE_CAT, d.NAME, d.CODE, d.IDT_REQUIRED, d.VERSION_IDT, d.BASE_TYPE, d.IS_READY, d.hashdiff_full, d.source_event_date, d.Record_source, d.load_timestamp
FROM dedup d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_way4_ows_td_auth_type') t
    ON t.Ref_hashkey = d.Ref_hashkey;
