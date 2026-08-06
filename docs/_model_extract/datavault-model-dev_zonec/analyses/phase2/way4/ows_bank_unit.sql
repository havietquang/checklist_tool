DROP TEMPORARY TABLE IF EXISTS src_ows_bank_unit;
CREATE TEMPORARY TABLE src_ows_bank_unit AS SELECT * FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_bank_unit');
-- Source: way4.ows_bank_unit (raw: way4.ows_bank_unit) | Target: ref_way4_ows_bank_unit (phase2)
-- Reference full load | Ref_code = cast(id || code as string) | filter: AMND_STATE  = 'A'
-- hashdiff_full = sha2 toan bo cot nguon (giong macro stage) | source_event_date = start_date
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_way4_ows_bank_unit')
(Ref_hashkey, Ref_type, Ref_code, Ref_description, AMND_STATE, AMND_DATE, AMND_OFFICER, AMND_PREV, ID, NAME, CODE, UNIT_TYPE, BANK_UNIT__OID, F_I, LIAB_CONTRACT, BANK_CLIENT, IS_READY, hashdiff_full, source_event_date, Record_source, load_timestamp)
WITH base AS (
    SELECT
        sha2(('w4_ows_bank_unit' || cast(id || code as string)), 256) AS Ref_hashkey,
        'w4_ows_bank_unit' AS Ref_type,
        cast(id || code as string) AS Ref_code,
        cast(name as string) AS Ref_description,
        AMND_STATE,
        AMND_DATE,
        AMND_OFFICER,
        AMND_PREV,
        ID,
        NAME,
        CODE,
        UNIT_TYPE,
        BANK_UNIT__OID,
        F_I,
        LIAB_CONTRACT,
        BANK_CLIENT,
        IS_READY,
        sha2(COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(unit_type AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(bank_unit__oid AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(f_i AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(liab_contract AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(bank_client AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(is_ready AS string))), ''), 256) AS hashdiff_full,
        to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_bank_unit' as string) AS Record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM src_ows_bank_unit
    WHERE AMND_STATE  = 'A'
),
dedup AS (
    SELECT * FROM base
    WHERE Ref_hashkey IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY Ref_hashkey ORDER BY source_event_date DESC) = 1
)
SELECT d.Ref_hashkey, d.Ref_type, d.Ref_code, d.Ref_description, d.AMND_STATE, d.AMND_DATE, d.AMND_OFFICER, d.AMND_PREV, d.ID, d.NAME, d.CODE, d.UNIT_TYPE, d.BANK_UNIT__OID, d.F_I, d.LIAB_CONTRACT, d.BANK_CLIENT, d.IS_READY, d.hashdiff_full, d.source_event_date, d.Record_source, d.load_timestamp
FROM dedup d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_way4_ows_bank_unit') t
    ON t.Ref_hashkey = d.Ref_hashkey;
