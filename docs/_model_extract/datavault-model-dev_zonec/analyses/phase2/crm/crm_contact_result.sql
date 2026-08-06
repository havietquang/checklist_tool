-- ============================================================
-- Source table  : .crm.crm_contact_result
-- Target tables : ref_crm_contact_result
-- Date range    : fullload {{start_date}}=20250101
-- ============================================================

DROP TEMPORARY TABLE IF EXISTS tmp_crm_contact_result; CREATE TEMPORARY TABLE tmp_crm_contact_result AS
SELECT
    contact_result_id, contact_result_name, status, position, insurance,
    expired_card_prio, cust_group
FROM IDENTIFIER({{catalog_sourcing}} || '.crm.crm_contact_result')
WHERE contact_result_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_crm_contact_result')
(Ref_hashkey, Ref_type, Ref_code, Ref_description, status, position, insurance,
 expired_card_prio, cust_group, hashdiff_full, source_event_date, Record_source, load_timestamp)
WITH src AS (
    SELECT
        sha2(('crm_contact_result' || CAST(contact_result_id AS string)), 256) AS Ref_hashkey,
        'crm_contact_result' AS Ref_type,
        CAST(contact_result_id AS string) AS Ref_code,
        CAST(contact_result_name AS string) AS Ref_description,
        status,
        position,
        insurance,
        expired_card_prio,
        cust_group,
        sha2(COALESCE(UPPER(TRIM(CAST(contact_result_id   AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(contact_result_name AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(status              AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(position            AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(insurance           AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(expired_card_prio   AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(cust_group          AS string))), ''), 256) AS hashdiff_full,
        to_date({{start_date}}, 'yyyyMMdd') AS source_event_date
    FROM tmp_crm_contact_result
    WHERE contact_result_id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY contact_result_id ORDER BY 1) = 1
)
SELECT
    d.Ref_hashkey AS Ref_hashkey,
    d.Ref_type AS Ref_type,
    d.Ref_code AS Ref_code,
    d.Ref_description AS Ref_description,
    d.status AS status,
    d.position AS position,
    d.insurance AS insurance,
    d.expired_card_prio AS expired_card_prio,
    d.cust_group AS cust_group,
    d.hashdiff_full AS hashdiff_full,
    d.source_event_date AS source_event_date,
    'crm__crm_contact_result' AS Record_source,
    current_timestamp() AS load_timestamp
FROM src d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_crm_contact_result') t
    ON t.Ref_hashkey = d.Ref_hashkey AND t.hashdiff_full = d.hashdiff_full;

DROP TEMPORARY TABLE IF EXISTS tmp_crm_contact_result;
