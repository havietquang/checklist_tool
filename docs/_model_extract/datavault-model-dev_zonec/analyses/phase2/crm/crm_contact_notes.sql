-- ============================================================
-- Source table  : .crm.crm_contact_notes
-- Target tables : hub_crm_contact_notes
--                 sat_crm_contact_notes_information
-- Date range    : fullload {{start_date}}=20250101
-- ============================================================

DROP TEMPORARY TABLE IF EXISTS tmp_crm_contact_notes; CREATE TEMPORARY TABLE tmp_crm_contact_notes AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(ID AS string))), ''), 256) AS crm_contact_notes_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(NAME                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(STATUS                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(DATE_CREATED          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(USER_CREATED          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(DATE_UPDATED          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(USER_UPDATED          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(IS_IMPORTED           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(PROGRAM_TYPE          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(PROGRAM_CODE          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(IS_PROGRAM_HOT        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(END_DATE_PROGRAM      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(START_DATE_PROGRAM    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ID_PRODUCT            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(CUSTGROUP             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(DEPARTMENT            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(PARENT_KEY            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(FILE_BANNER           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(FILE_MANUAL           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(FILE_INFO_PROD        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(DATA_TYPE             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(POSITION              AS string))), ''), 256) AS hd_contact_notes_information,
    to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
    ID, NAME, STATUS, DATE_CREATED, USER_CREATED, DATE_UPDATED, USER_UPDATED,
    IS_IMPORTED, PROGRAM_TYPE, PROGRAM_CODE, IS_PROGRAM_HOT, END_DATE_PROGRAM,
    START_DATE_PROGRAM, ID_PRODUCT, CUSTGROUP, DEPARTMENT, PARENT_KEY,
    FILE_BANNER, FILE_MANUAL, FILE_INFO_PROD, DATA_TYPE, POSITION
FROM IDENTIFIER({{catalog_sourcing}} || '.crm.crm_contact_notes')
WHERE ID IS NOT NULL;

-- ============================================================
-- INSERT HUB: hub_crm_contact_notes
-- ============================================================
-- [hub_crm_contact_notes] Consolidated insert from ALL sources to avoid Delta version conflicts.
-- Nguon: crm_contact_notes (ID) + crm_contact_hist (CONTACTNOTEID). File crm_contact_hist.sql khong INSERT hub nay nua.
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_crm_contact_notes')
(crm_contact_notes_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH all_sources AS (
    SELECT crm_contact_notes_hashkey,
           CAST(ID AS STRING) AS business_key,
           source_event_date,
           'crm__crm_contact_notes' AS record_source,
           1 AS source_priority
    FROM tmp_crm_contact_notes
    UNION ALL
    SELECT sha2(COALESCE(UPPER(TRIM(CAST(CONTACTNOTEID AS string))), ''), 256) AS crm_contact_notes_hashkey,
           CAST(CONTACTNOTEID AS STRING) AS business_key,
           to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
           'crm__crm_contact_hist' AS record_source,
           2 AS source_priority
    FROM (SELECT DISTINCT CONTACTNOTEID FROM IDENTIFIER({{catalog_sourcing}} || '.crm.crm_contact_hist') WHERE CONTACTNOTEID IS NOT NULL)
),
deduped AS (
    SELECT * FROM all_sources
    QUALIFY ROW_NUMBER() OVER (PARTITION BY crm_contact_notes_hashkey ORDER BY source_priority) = 1
)
SELECT
    d.crm_contact_notes_hashkey AS crm_contact_notes_hashkey,
    d.business_key AS business_key,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    d.record_source AS record_source
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_crm_contact_notes') t
    ON t.crm_contact_notes_hashkey = d.crm_contact_notes_hashkey;

-- ============================================================
-- INSERT SATELLITE: sat_crm_contact_notes_information
-- ============================================================
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_crm_contact_notes_information')
(crm_contact_notes_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 name, status, date_created, user_created, date_updated, user_updated,
 is_imported, program_type, program_code, is_program_hot, end_date_program,
 start_date_program, id_product, custgroup, department, parent_key,
 file_banner, file_manual, file_info_prod, data_type, position)
WITH deduped AS (SELECT * FROM tmp_crm_contact_notes QUALIFY ROW_NUMBER() OVER (PARTITION BY crm_contact_notes_hashkey, hd_contact_notes_information ORDER BY 1) = 1)
SELECT
    d.crm_contact_notes_hashkey AS crm_contact_notes_hashkey,
    d.hd_contact_notes_information AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'crm__crm_contact_notes' AS record_source,
    d.NAME AS name,
    d.STATUS AS status,
    d.DATE_CREATED AS date_created,
    d.USER_CREATED AS user_created,
    d.DATE_UPDATED AS date_updated,
    d.USER_UPDATED AS user_updated,
    d.IS_IMPORTED AS is_imported,
    d.PROGRAM_TYPE AS program_type,
    d.PROGRAM_CODE AS program_code,
    d.IS_PROGRAM_HOT AS is_program_hot,
    d.END_DATE_PROGRAM AS end_date_program,
    d.START_DATE_PROGRAM AS start_date_program,
    d.ID_PRODUCT AS id_product,
    d.CUSTGROUP AS custgroup,
    d.DEPARTMENT AS department,
    d.PARENT_KEY AS parent_key,
    d.FILE_BANNER AS file_banner,
    d.FILE_MANUAL AS file_manual,
    d.FILE_INFO_PROD AS file_info_prod,
    d.DATA_TYPE AS data_type,
    d.POSITION AS position
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_crm_contact_notes_information') t
    ON t.crm_contact_notes_hashkey = d.crm_contact_notes_hashkey AND t.hashdiff = d.hd_contact_notes_information;

DROP TEMPORARY TABLE IF EXISTS tmp_crm_contact_notes;
