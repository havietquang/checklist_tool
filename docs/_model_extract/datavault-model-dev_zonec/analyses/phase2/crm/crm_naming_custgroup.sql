-- ============================================================
-- Source table  : .crm.crm_naming_custgroup
-- Target tables : ref_crm_custgroup
-- Date range    : fullload {{start_date}}=20250101
-- ============================================================

DROP TEMPORARY TABLE IF EXISTS tmp_crm_naming_custgroup; CREATE TEMPORARY TABLE tmp_crm_naming_custgroup AS
SELECT
    custgroup, name, parent_key, user_created, date_created, user_updated,
    date_updated, user_deleted, date_deleted, isactive, isdeleted
FROM IDENTIFIER({{catalog_sourcing}} || '.crm.crm_naming_custgroup')
WHERE custgroup IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_crm_custgroup')
(Ref_hashkey, Ref_type, Ref_code, Ref_description, parent_key, user_created, date_created,
 user_updated, date_updated, user_deleted, date_deleted, isactive, isdeleted,
 hashdiff_full, source_event_date, Record_source, load_timestamp)
WITH src AS (
    SELECT
        sha2(('crm_custgroup' || CAST(custgroup AS string)), 256) AS Ref_hashkey,
        'crm_custgroup' AS Ref_type,
        CAST(custgroup AS string) AS Ref_code,
        CAST(name AS string) AS Ref_description,
        parent_key,
        user_created,
        date_created,
        user_updated,
        date_updated,
        user_deleted,
        date_deleted,
        isactive,
        isdeleted,
        sha2(COALESCE(UPPER(TRIM(CAST(custgroup    AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(name         AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(parent_key   AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(user_created AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(date_created AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(user_updated AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(date_updated AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(user_deleted AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(date_deleted AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(isactive     AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(isdeleted    AS string))), ''), 256) AS hashdiff_full,
        to_date({{start_date}}, 'yyyyMMdd') AS source_event_date
    FROM tmp_crm_naming_custgroup
    WHERE custgroup IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY custgroup ORDER BY 1) = 1
)
SELECT
    d.Ref_hashkey AS Ref_hashkey,
    d.Ref_type AS Ref_type,
    d.Ref_code AS Ref_code,
    d.Ref_description AS Ref_description,
    d.parent_key AS parent_key,
    d.user_created AS user_created,
    d.date_created AS date_created,
    d.user_updated AS user_updated,
    d.date_updated AS date_updated,
    d.user_deleted AS user_deleted,
    d.date_deleted AS date_deleted,
    d.isactive AS isactive,
    d.isdeleted AS isdeleted,
    d.hashdiff_full AS hashdiff_full,
    d.source_event_date AS source_event_date,
    'crm__crm_custgroup' AS Record_source,
    current_timestamp() AS load_timestamp
FROM src d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_crm_custgroup') t
    ON t.Ref_hashkey = d.Ref_hashkey AND t.hashdiff_full = d.hashdiff_full;

DROP TEMPORARY TABLE IF EXISTS tmp_crm_naming_custgroup;
