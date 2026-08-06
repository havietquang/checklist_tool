-- ============================================================
-- Source table  : .crm.crm_contact_hist
-- Target tables : hub_crm_contact_hist
--                 sat_crm_contact_hist_information
--                 hub_crm_contact_notes (via contactnoteid)
-- Date range    : fullload {{start_date}}=20250101
-- ============================================================

DROP TEMPORARY TABLE IF EXISTS tmp_crm_contact_hist; CREATE TEMPORARY TABLE tmp_crm_contact_hist AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(ID AS string))), ''), 256) AS crm_contact_hist_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(CIF                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(DATE_CONTACT         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(FUNC_GROUP           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(BRANCH_CODE          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(NOTES                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(SOUCRE               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(CONTACT_STATUS_ID    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(CONTACT_TYPE_ID      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(CONTACT_RESULT_ID    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(CONTACTNOTEID        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(IMPORT_ID            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(PROGRAM_NOTYFY_ID    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(SALE_CODE            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(PROMISE_DATE         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(RECALL_DATE          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(CONDITION_DATE       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(REFERENCES_DATE      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(DIALID               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(DATETIME_CREATED     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(DATETIME_UPDATED     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(USER_CREATED         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(USER_UPDATED         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(UPDATE_TIMES         AS string))), ''), 256) AS hd_contact_hist_information,
    to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
    ID, CIF, DATE_CONTACT, FUNC_GROUP, BRANCH_CODE, NOTES, SOUCRE,
    CONTACT_STATUS_ID, CONTACT_TYPE_ID, CONTACT_RESULT_ID, CONTACTNOTEID,
    IMPORT_ID, PROGRAM_NOTYFY_ID, SALE_CODE, PROMISE_DATE, RECALL_DATE,
    CONDITION_DATE, REFERENCES_DATE, DIALID, DATETIME_CREATED, DATETIME_UPDATED,
    USER_CREATED, USER_UPDATED, UPDATE_TIMES
FROM IDENTIFIER({{catalog_sourcing}} || '.crm.crm_contact_hist')
WHERE ID IS NOT NULL;

-- ============================================================
-- INSERT HUB: hub_crm_contact_hist
-- ============================================================
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_crm_contact_hist')
(crm_contact_hist_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_crm_contact_hist QUALIFY ROW_NUMBER() OVER (PARTITION BY crm_contact_hist_hashkey ORDER BY 1) = 1)
SELECT
    d.crm_contact_hist_hashkey AS crm_contact_hist_hashkey,
    d.ID AS business_key,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'crm__contact_hist' AS record_source
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_crm_contact_hist') t
    ON t.crm_contact_hist_hashkey = d.crm_contact_hist_hashkey;

-- ============================================================
-- [hub_crm_contact_notes] Moved to crm_contact_notes.sql (consolidated UNION ALL to avoid Delta version conflicts)
-- Nguon CONTACTNOTEID da duoc gop vao all_sources trong crm_contact_notes.sql
-- ============================================================

-- ============================================================
-- INSERT SATELLITE: sat_crm_contact_hist_information
-- ============================================================
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_crm_contact_hist_information')
(crm_contact_hist_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 CIF, DATE_CONTACT, FUNC_GROUP, BRANCH_CODE, NOTES, SOUCRE,
 CONTACT_STATUS_ID, CONTACT_TYPE_ID, CONTACT_RESULT_ID, CONTACTNOTEID,
 IMPORT_ID, PROGRAM_NOTYFY_ID, SALE_CODE, PROMISE_DATE, RECALL_DATE,
 CONDITION_DATE, REFERENCES_DATE, DIALID, DATETIME_CREATED, DATETIME_UPDATED,
 USER_CREATED, USER_UPDATED, UPDATE_TIMES)
WITH deduped AS (SELECT * FROM tmp_crm_contact_hist QUALIFY ROW_NUMBER() OVER (PARTITION BY crm_contact_hist_hashkey, hd_contact_hist_information ORDER BY 1) = 1)
SELECT
    d.crm_contact_hist_hashkey AS crm_contact_hist_hashkey,
    d.hd_contact_hist_information AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'crm__crm_contact_hist' AS record_source,
    d.CIF AS CIF,
    d.DATE_CONTACT AS DATE_CONTACT,
    d.FUNC_GROUP AS FUNC_GROUP,
    d.BRANCH_CODE AS BRANCH_CODE,
    d.NOTES AS NOTES,
    d.SOUCRE AS SOUCRE,
    d.CONTACT_STATUS_ID AS CONTACT_STATUS_ID,
    d.CONTACT_TYPE_ID AS CONTACT_TYPE_ID,
    d.CONTACT_RESULT_ID AS CONTACT_RESULT_ID,
    d.CONTACTNOTEID AS CONTACTNOTEID,
    d.IMPORT_ID AS IMPORT_ID,
    d.PROGRAM_NOTYFY_ID AS PROGRAM_NOTYFY_ID,
    d.SALE_CODE AS SALE_CODE,
    d.PROMISE_DATE AS PROMISE_DATE,
    d.RECALL_DATE AS RECALL_DATE,
    d.CONDITION_DATE AS CONDITION_DATE,
    d.REFERENCES_DATE AS REFERENCES_DATE,
    d.DIALID AS DIALID,
    d.DATETIME_CREATED AS DATETIME_CREATED,
    d.DATETIME_UPDATED AS DATETIME_UPDATED,
    d.USER_CREATED AS USER_CREATED,
    d.USER_UPDATED AS USER_UPDATED,
    d.UPDATE_TIMES AS UPDATE_TIMES
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_crm_contact_hist_information') t
    ON t.crm_contact_hist_hashkey = d.crm_contact_hist_hashkey AND t.hashdiff = d.hd_contact_hist_information;

-- ============================================================
-- LINK: link_contact_hist_callcenter (cross-source, tag:phase2)
-- ============================================================
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_contact_hist_callcenter')
(link_contact_hist_callcenter_hashkey, crm_contact_hist_hashkey, callcenter_hashkey,
 source_event_date, load_timestamp, record_source)
WITH callcenter_src AS (
    SELECT DISTINCT _id, dialid
    FROM IDENTIFIER({{catalog_sourcing}} || '.callcenter.callcenter')
    WHERE dialid IS NOT NULL AND _id IS NOT NULL
),
src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(t1.ID  AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t2._id AS string))), ''), 256) AS link_contact_hist_callcenter_hashkey,
        t1.crm_contact_hist_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t2._id AS string))), ''), 256) AS callcenter_hashkey,
        t1.source_event_date
    FROM tmp_crm_contact_hist t1
    JOIN callcenter_src t2 ON t1.DIALID = t2.dialid
    WHERE t1.DIALID IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY t1.ID, t2._id ORDER BY 1) = 1
)
SELECT
    d.link_contact_hist_callcenter_hashkey AS link_contact_hist_callcenter_hashkey,
    d.crm_contact_hist_hashkey AS crm_contact_hist_hashkey,
    d.callcenter_hashkey AS callcenter_hashkey,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'crm__crm_contact_hist' AS record_source
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_contact_hist_callcenter') t
    ON t.link_contact_hist_callcenter_hashkey = d.link_contact_hist_callcenter_hashkey;

-- LINK link_contact_hist_branch
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_contact_hist_branch')
(link_contact_hist_branch_hashkey, crm_contact_hist_hashkey, branch_hashkey,
 source_event_date, load_timestamp, record_source)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(ID AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(BRANCH_CODE AS string))), ''), 256) AS link_contact_hist_branch_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(ID AS string))), ''), 256) AS crm_contact_hist_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(BRANCH_CODE AS string))), ''), 256) AS branch_hashkey,
        source_event_date
    FROM tmp_crm_contact_hist
    WHERE BRANCH_CODE IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ID, BRANCH_CODE ORDER BY 1) = 1
)
SELECT
    d.link_contact_hist_branch_hashkey AS link_contact_hist_branch_hashkey,
    d.crm_contact_hist_hashkey AS crm_contact_hist_hashkey,
    d.branch_hashkey AS branch_hashkey,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'crm__crm_contact_hist' AS record_source
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_contact_hist_branch') t
    ON t.link_contact_hist_branch_hashkey = d.link_contact_hist_branch_hashkey;

-- LINK link_contact_hist_contact_notes
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_contact_hist_contact_notes')
(link_contact_hist_contact_notes_hashkey, crm_contact_hist_hashkey, crm_contact_notes_hashkey,
 source_event_date, load_timestamp, record_source)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(ID AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(CONTACTNOTEID AS string))), ''), 256) AS link_contact_hist_contact_notes_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(ID AS string))), ''), 256) AS crm_contact_hist_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(CONTACTNOTEID AS string))), ''), 256) AS crm_contact_notes_hashkey,
        source_event_date
    FROM tmp_crm_contact_hist
    WHERE CONTACTNOTEID IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ID, CONTACTNOTEID ORDER BY 1) = 1
)
SELECT
    d.link_contact_hist_contact_notes_hashkey AS link_contact_hist_contact_notes_hashkey,
    d.crm_contact_hist_hashkey AS crm_contact_hist_hashkey,
    d.crm_contact_notes_hashkey AS crm_contact_notes_hashkey,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'crm__crm_contact_hist' AS record_source
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_contact_hist_contact_notes') t
    ON t.link_contact_hist_contact_notes_hashkey = d.link_contact_hist_contact_notes_hashkey;

-- LINK link_contact_hist_customer
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_contact_hist_customer')
(link_contact_hist_customer_hashkey, crm_contact_hist_hashkey, customer_hashkey,
 source_event_date, load_timestamp, record_source)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(ID AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(CIF AS string))), ''), 256) AS link_contact_hist_customer_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(ID AS string))), ''), 256) AS crm_contact_hist_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(CIF AS string))), ''), 256) AS customer_hashkey,
        source_event_date
    FROM tmp_crm_contact_hist
    WHERE CIF IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ID, CIF ORDER BY 1) = 1
)
SELECT
    d.link_contact_hist_customer_hashkey AS link_contact_hist_customer_hashkey,
    d.crm_contact_hist_hashkey AS crm_contact_hist_hashkey,
    d.customer_hashkey AS customer_hashkey,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'crm__crm_contact_hist' AS record_source
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_contact_hist_customer') t
    ON t.link_contact_hist_customer_hashkey = d.link_contact_hist_customer_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_crm_contact_hist;
