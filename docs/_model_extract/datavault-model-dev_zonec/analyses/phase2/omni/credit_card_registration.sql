-- Source: omni.credit_card_registration | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_credit_card_registration; CREATE TEMPORARY TABLE tmp_credit_card_registration AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS credit_card_registration_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(number_of_dependents AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(job AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(company_address AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(company_address_info AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(company_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(type_of_labor_contract AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(position AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(working_time AS string))), ''), 256) AS hd_credit_card_registration_customer_info,
    sha2(COALESCE(UPPER(TRIM(CAST(income_method AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(debt_expenses_to_pay_other_credit_institutions AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(real_monthly_income AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(living_expenses AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(salary_income AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(business_income AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(vehicle_rental_income AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(real_estate_rental_income AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(other_income AS string))), ''), 256) AS hd_credit_card_registration_financial_profile,
    sha2(COALESCE(UPPER(TRIM(CAST(ekyc_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(face_liveness_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(face_matching_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(face_sanity_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(id_card_ocr_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(id_card_sanity_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(in_import_list AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(signed_contract_file_path AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contract_file_path AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(document_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(agreement_uuid AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contract_no AS string))), ''), 256) AS hd_credit_card_registration_flow,
    sha2(COALESCE(UPPER(TRIM(CAST(card_limit_approved AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sale_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(personal_rank AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(personal_rank_start AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(personal_rank_renew AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(group_personal_rank AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(card_issuance_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(process_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(policy_groups AS string))), ''), 256) AS hd_credit_card_registration_information,
    sha2(COALESCE(UPPER(TRIM(CAST(introduce_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(introduce_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(referral_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(reference_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(reference_phone_number AS string))), ''), 256) AS hd_credit_card_registration_introduce,
    sha2(COALESCE(UPPER(TRIM(CAST(birthday AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contact_address AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(customer_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(email AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(id_card_tampering_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(legal_id_num AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(legal_issue_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(legal_issue_place AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(limit_suggest AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(marital_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(legal_id_num_other AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(permanent_address AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phone_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(product_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(product_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(branch_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(branch_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(card_repayment_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(card_repayment_account_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(delivery_address AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_legal_id_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(legal_id_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(legal_expired_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gender AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sale_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nationality AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(education_level AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(card_token_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(spouse_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(spouse_legal_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(spouse_legal_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(product_code_offer AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(product_name_offer AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(product_code_offer_list AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(spouse_phone_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(relationship_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(reference_id AS string))), ''), 256) AS hd_credit_card_registration_other,
    CAST(LEAST(CAST(UPDATED_DATE AS DATE), CAST(CREATED_DATE AS DATE)) AS DATE) AS source_event_date,
    id, number_of_dependents, job, company_address, company_address_info, company_name,
    type_of_labor_contract, position, working_time,
    income_method, debt_expenses_to_pay_other_credit_institutions, real_monthly_income, living_expenses,
    salary_income, business_income, vehicle_rental_income, real_estate_rental_income, other_income,
    ekyc_type, face_liveness_status, face_matching_status, face_sanity_status, id_card_ocr_status,
    id_card_sanity_status, in_import_list, signed_contract_file_path, contract_file_path,
    document_id, agreement_uuid, contract_no,
    card_limit_approved, created_date, updated_date, status, sale_code, personal_rank,
    personal_rank_start, personal_rank_renew, group_personal_rank, card_issuance_type,
    process_type, policy_groups,
    introduce_name, introduce_code, referral_code, reference_name, reference_phone_number,
    birthday, contact_address, customer_name, email, id_card_tampering_status, legal_id_num,
    legal_issue_date, legal_issue_place, limit_suggest, marital_status, legal_id_num_other,
    permanent_address, phone_number, product_code, product_name, branch_name, branch_code,
    card_repayment_type, card_repayment_account_no, delivery_address, old_legal_id_no,
    legal_id_type, legal_expired_date, gender, sale_name, nationality, education_level,
    card_token_number, spouse_name, spouse_legal_type, spouse_legal_id, product_code_offer,
    product_name_offer, product_code_offer_list, spouse_phone_number, relationship_type,
    reference_id
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.credit_card_registration')
WHERE LEAST(CAST(UPDATED_DATE AS DATE), CAST(CREATED_DATE AS DATE)) BETWEEN to_date({{start_date}}, 'yyyyMMdd') AND to_date({{end_date}}, 'yyyyMMdd')
  AND id IS NOT NULL;

-- SAT credit_card_registration_other
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_credit_card_registration_other')
(credit_card_registration_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 birthday, contact_address, customer_name, email, id_card_tampering_status, legal_id_num,
 legal_issue_date, legal_issue_place, limit_suggest, marital_status, legal_id_num_other,
 permanent_address, phone_number, product_code, product_name, branch_name, branch_code,
 card_repayment_type, card_repayment_account_no, delivery_address, old_legal_id_no,
 legal_id_type, legal_expired_date, gender, sale_name, nationality, education_level,
 card_token_number, spouse_name, spouse_legal_type, spouse_legal_id, product_code_offer,
 product_name_offer, product_code_offer_list, spouse_phone_number, relationship_type, reference_id)
WITH deduped AS (
    SELECT * FROM tmp_credit_card_registration
    QUALIFY ROW_NUMBER() OVER (PARTITION BY credit_card_registration_hashkey, hd_credit_card_registration_other ORDER BY source_event_date) = 1
)
SELECT
    d.credit_card_registration_hashkey AS credit_card_registration_hashkey,
    d.hd_credit_card_registration_other AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__credit_card_registration' AS record_source,
    d.birthday AS birthday,
    d.contact_address AS contact_address,
    d.customer_name AS customer_name,
    d.email AS email,
    d.id_card_tampering_status AS id_card_tampering_status,
    d.legal_id_num AS legal_id_num,
    d.legal_issue_date AS legal_issue_date,
    d.legal_issue_place AS legal_issue_place,
    d.limit_suggest AS limit_suggest,
    d.marital_status AS marital_status,
    d.legal_id_num_other AS legal_id_num_other,
    d.permanent_address AS permanent_address,
    d.phone_number AS phone_number,
    d.product_code AS product_code,
    d.product_name AS product_name,
    d.branch_name AS branch_name,
    d.branch_code AS branch_code,
    d.card_repayment_type AS card_repayment_type,
    d.card_repayment_account_no AS card_repayment_account_no,
    d.delivery_address AS delivery_address,
    d.old_legal_id_no AS old_legal_id_no,
    d.legal_id_type AS legal_id_type,
    d.legal_expired_date AS legal_expired_date,
    d.gender AS gender,
    d.sale_name AS sale_name,
    d.nationality AS nationality,
    d.education_level AS education_level,
    d.card_token_number AS card_token_number,
    d.spouse_name AS spouse_name,
    d.spouse_legal_type AS spouse_legal_type,
    d.spouse_legal_id AS spouse_legal_id,
    d.product_code_offer AS product_code_offer,
    d.product_name_offer AS product_name_offer,
    d.product_code_offer_list AS product_code_offer_list,
    d.spouse_phone_number AS spouse_phone_number,
    d.relationship_type AS relationship_type,
    d.reference_id AS reference_id
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_credit_card_registration_other') t
    ON t.credit_card_registration_hashkey = d.credit_card_registration_hashkey AND t.hashdiff = d.hd_credit_card_registration_other;

DROP TEMPORARY TABLE IF EXISTS tmp_credit_card_registration;
