DROP TEMPORARY TABLE IF EXISTS src_ows_evnt_action;
CREATE TEMPORARY TABLE src_ows_evnt_action AS SELECT * FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_evnt_action');
-- Source: way4.ows_evnt_action (raw: way4.ows_evnt_action) | Target: ref_way4_ows_evnt_action (phase2)
-- Reference full load | Ref_code = cast(id || ACTION_CODE as string) | filter: không lọc (straight move)
-- hashdiff_full = sha2 toan bo cot nguon (giong macro stage)| source_event_date = start_date
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_way4_ows_evnt_action')
(Ref_hashkey, Ref_type, Ref_code, Ref_description, ID, USAGE_ACTION__OID, ACTION_CODE, NEW_ID, OLD_ID, STATUS, EVENT_DETAILS, DATA_DATE, hashdiff_full, source_event_date, Record_source, load_timestamp)
WITH base AS (
    SELECT
        sha2(('w4_ows_evnt_action' || cast(id || ACTION_CODE as string)), 256) AS Ref_hashkey,
        'w4_ows_evnt_action' AS Ref_type,
        cast(id || ACTION_CODE as string) AS Ref_code,
        cast(EVENT_DETAILS as string) AS Ref_description,
        ID,
        USAGE_ACTION__OID,
        ACTION_CODE,
        NEW_ID,
        OLD_ID,
        STATUS,
        EVENT_DETAILS,
        DATA_DATE,
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(usage_action__oid AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(action_code AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(new_id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(old_id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(event_details AS string))), ''), 256) AS hashdiff_full,
        to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_evnt_action' as string) AS Record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM src_ows_evnt_action
),
dedup AS (
    SELECT * FROM base
    WHERE Ref_hashkey IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY Ref_hashkey ORDER BY source_event_date DESC) = 1
)
SELECT d.Ref_hashkey, d.Ref_type, d.Ref_code, d.Ref_description, d.ID, d.USAGE_ACTION__OID, d.ACTION_CODE, d.NEW_ID, d.OLD_ID, d.STATUS, d.EVENT_DETAILS, d.DATA_DATE, d.hashdiff_full, d.source_event_date, d.Record_source, d.load_timestamp
FROM dedup d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_way4_ows_evnt_action') t
    ON t.Ref_hashkey = d.Ref_hashkey;
