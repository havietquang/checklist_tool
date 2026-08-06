DROP TEMPORARY TABLE IF EXISTS src_ows_event_type;
CREATE TEMPORARY TABLE src_ows_event_type AS SELECT * FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_event_type');
-- Source: way4.ows_event_type (raw: way4.ows_event_type) | Target: ref_way4_ows_event_type (phase2)
-- Reference full load | Ref_code = concat_ws('', cast(id as string), cast(code as string)) | filter: AMND_STATE  = 'A'
-- hashdiff_full = sha2 toan bo cot nguon (giong macro stage) | source_event_date = start_date
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_way4_ows_event_type')
(Ref_hashkey, Ref_type, Ref_code, Ref_description, AMND_STATE, AMND_DATE, AMND_OFFICER, AMND_PREV, ID, NAME, GROUP_CODE, CODE, F_I, PCAT, CON_CAT, EVENT_RENEW_TYPE, EVENT_PERIOD, DUE_TO_WORK_DAY, POST_IMMEDIATE, FEE_TYPE, NEW_STATUS, NEXT_EVENT, START_JOB, CLIENT_STOP_LIST, CR_LIMIT_ACTION, USED_IN_HISTORY, SUPPL_FORMULA, CUSTOM_EVENT_CODE, SPECIAL_PARMS, hashdiff_full, source_event_date, Record_source, load_timestamp)
WITH base AS (
    SELECT
        sha2(('w4_ows_event_type' || concat_ws('', cast(id as string), cast(code as string))), 256) AS Ref_hashkey,
        'w4_ows_event_type' AS Ref_type,
        concat_ws('', cast(id as string), cast(code as string)) AS Ref_code,
        cast(name as string) AS Ref_description,
        AMND_STATE,
        AMND_DATE,
        AMND_OFFICER,
        AMND_PREV,
        ID,
        NAME,
        GROUP_CODE,
        CODE,
        F_I,
        PCAT,
        CON_CAT,
        EVENT_RENEW_TYPE,
        EVENT_PERIOD,
        DUE_TO_WORK_DAY,
        POST_IMMEDIATE,
        FEE_TYPE,
        NEW_STATUS,
        NEXT_EVENT,
        START_JOB,
        CLIENT_STOP_LIST,
        CR_LIMIT_ACTION,
        USED_IN_HISTORY,
        SUPPL_FORMULA,
        CUSTOM_EVENT_CODE,
        SPECIAL_PARMS,
        sha2(COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(group_code AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(f_i AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(pcat AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(con_cat AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(event_renew_type AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(event_period AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(due_to_work_day AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(post_immediate AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(fee_type AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(new_status AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(next_event AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(start_job AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(client_stop_list AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(cr_limit_action AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(used_in_history AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(suppl_formula AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(custom_event_code AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(special_parms AS string))), ''), 256) AS hashdiff_full,
        to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_event_type' as string) AS Record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM src_ows_event_type
    WHERE AMND_STATE  = 'A'
),
dedup AS (
    SELECT * FROM base
    WHERE Ref_hashkey IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY Ref_hashkey ORDER BY source_event_date DESC) = 1
)
SELECT d.Ref_hashkey, d.Ref_type, d.Ref_code, d.Ref_description, d.AMND_STATE, d.AMND_DATE, d.AMND_OFFICER, d.AMND_PREV, d.ID, d.NAME, d.GROUP_CODE, d.CODE, d.F_I, d.PCAT, d.CON_CAT, d.EVENT_RENEW_TYPE, d.EVENT_PERIOD, d.DUE_TO_WORK_DAY, d.POST_IMMEDIATE, d.FEE_TYPE, d.NEW_STATUS, d.NEXT_EVENT, d.START_JOB, d.CLIENT_STOP_LIST, d.CR_LIMIT_ACTION, d.USED_IN_HISTORY, d.SUPPL_FORMULA, d.CUSTOM_EVENT_CODE, d.SPECIAL_PARMS, d.hashdiff_full, d.source_event_date, d.Record_source, d.load_timestamp
FROM dedup d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_way4_ows_event_type') t
    ON t.Ref_hashkey = d.Ref_hashkey;
