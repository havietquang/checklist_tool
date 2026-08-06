-- Source: omni.od_registration | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_od_registration; CREATE TEMPORARY TABLE tmp_od_registration AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS od_registration_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(requested_limit_amount AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(approved_limit_amount AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_rate AS string))), ''), 256) AS hd_od_registration_limit,
    sha2(COALESCE(UPPER(TRIM(CAST(contract_file_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(result_file_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(approval_file_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contract_bill_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(first_approval_agreement_uuid AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(first_approval_bill_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(second_approval_agreement_uuid AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(second_approval_bill_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ecm_approval_document_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ecm_contract_document_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(prepare_certificate_request_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(confirmation_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(approval_agreement_id AS string))), ''), 256) AS hd_od_registration_agreement,
    sha2(COALESCE(UPPER(TRIM(CAST(due_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(effective_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(requested_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(issued_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_at AS string))), ''), 256) AS hd_od_registration_date,
    sha2(COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(full_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(identity_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(email AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phone_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(address AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(username AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(issued_by AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_by AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_by AS string))), ''), 256) AS hd_od_registration_information,
    LEAST(CAST(UPDATED_AT AS DATE), CAST(CREATED_AT AS DATE)) AS source_event_date,
    id, requested_limit_amount, approved_limit_amount, interest_rate,
    contract_file_id, result_file_id, approval_file_id, contract_bill_code,
    first_approval_agreement_uuid, first_approval_bill_code, second_approval_agreement_uuid,
    second_approval_bill_code, ecm_approval_document_id, ecm_contract_document_id,
    prepare_certificate_request_id, confirmation_id, approval_agreement_id,
    due_date, effective_date, requested_date, issued_date, created_at, updated_at,
    status, full_name, identity_number, email, phone_number, address, username,
    issued_by, created_by, updated_by
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.od_registration')
WHERE LEAST(CAST(UPDATED_AT AS DATE), CAST(CREATED_AT AS DATE)) BETWEEN to_date({{start_date}}, 'yyyyMMdd') AND to_date({{end_date}}, 'yyyyMMdd')
  AND id IS NOT NULL;

-- SAT od_registration_agreement
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_od_registration_agreement')
(od_registration_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 contract_file_id, result_file_id, approval_file_id, contract_bill_code,
 first_approval_agreement_uuid, first_approval_bill_code, second_approval_agreement_uuid,
 second_approval_bill_code, ecm_approval_document_id, ecm_contract_document_id,
 prepare_certificate_request_id, confirmation_id, approval_agreement_id)
WITH deduped AS (
    SELECT * FROM tmp_od_registration
    QUALIFY ROW_NUMBER() OVER (PARTITION BY od_registration_hashkey, hd_od_registration_agreement ORDER BY source_event_date) = 1
)
SELECT
    d.od_registration_hashkey AS od_registration_hashkey,
    d.hd_od_registration_agreement AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__od_registration' AS record_source,
    d.contract_file_id AS contract_file_id,
    d.result_file_id AS result_file_id,
    d.approval_file_id AS approval_file_id,
    d.contract_bill_code AS contract_bill_code,
    d.first_approval_agreement_uuid AS first_approval_agreement_uuid,
    d.first_approval_bill_code AS first_approval_bill_code,
    d.second_approval_agreement_uuid AS second_approval_agreement_uuid,
    d.second_approval_bill_code AS second_approval_bill_code,
    d.ecm_approval_document_id AS ecm_approval_document_id,
    d.ecm_contract_document_id AS ecm_contract_document_id,
    d.prepare_certificate_request_id AS prepare_certificate_request_id,
    d.confirmation_id AS confirmation_id,
    d.approval_agreement_id AS approval_agreement_id
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_od_registration_agreement') t
    ON t.od_registration_hashkey = d.od_registration_hashkey AND t.hashdiff = d.hd_od_registration_agreement;

-- SAT od_registration_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_od_registration_information')
(od_registration_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 status, full_name, identity_number, email, phone_number, address, username,
 issued_by, created_by, updated_by)
WITH deduped AS (
    SELECT * FROM tmp_od_registration
    QUALIFY ROW_NUMBER() OVER (PARTITION BY od_registration_hashkey, hd_od_registration_information ORDER BY source_event_date) = 1
)
SELECT
    d.od_registration_hashkey AS od_registration_hashkey,
    d.hd_od_registration_information AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__od_registration' AS record_source,
    d.status AS status,
    d.full_name AS full_name,
    d.identity_number AS identity_number,
    d.email AS email,
    d.phone_number AS phone_number,
    d.address AS address,
    d.username AS username,
    d.issued_by AS issued_by,
    d.created_by AS created_by,
    d.updated_by AS updated_by
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_od_registration_information') t
    ON t.od_registration_hashkey = d.od_registration_hashkey AND t.hashdiff = d.hd_od_registration_information;

DROP TEMPORARY TABLE IF EXISTS tmp_od_registration;
