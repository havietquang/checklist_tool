-- Source: omni.party | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_party; CREATE TEMPORARY TABLE tmp_party AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS party_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(last_payment_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(last_payment_amount AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(action AS string))), ''), 256) AS hd_party_business,
    sha2(COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(category AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(type AS string))), ''), 256) AS hd_party_classification,
    sha2(COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(alias AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contact_person AS string))), ''), 256) AS hd_party_information,
    sha2(COALESCE(UPPER(TRIM(CAST(access_context_scope AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bb_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(email_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phone_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(legal_entity_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(service_agreement_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(external_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(approval_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(active_party_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(import_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(user_reference AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contact_reference AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(searchable_field_one AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(searchable_field_two AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(additions AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(address_line1 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(address_line2 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(street_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(town AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(country AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(post_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(country_sub_division AS string))), ''), 256) AS hd_party_other,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id, last_payment_date, last_payment_amount, action,
    status, category, type,
    name, alias, contact_person,
    access_context_scope, bb_id, email_id, phone_number, legal_entity_id, service_agreement_id,
    external_id, approval_id, active_party_id, import_id, user_reference, contact_reference,
    searchable_field_one, searchable_field_two, created_at, updated_at, additions,
    address_line1, address_line2, street_name, town, country, post_code, country_sub_division
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.party')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}}
  AND id IS NOT NULL;

-- SAT party_other
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_party_other')
(party_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 access_context_scope, bb_id, email_id, phone_number, legal_entity_id, service_agreement_id,
 external_id, approval_id, active_party_id, import_id, user_reference, contact_reference,
 searchable_field_one, searchable_field_two, created_at, updated_at, additions,
 address_line1, address_line2, street_name, town, country, post_code, country_sub_division)
WITH deduped AS (
    SELECT * FROM tmp_party
    QUALIFY ROW_NUMBER() OVER (PARTITION BY party_hashkey, hd_party_other ORDER BY data_date) = 1
)
SELECT
    d.party_hashkey AS party_hashkey,
    d.hd_party_other AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__party' AS record_source,
    d.access_context_scope AS access_context_scope,
    d.bb_id AS bb_id,
    d.email_id AS email_id,
    d.phone_number AS phone_number,
    d.legal_entity_id AS legal_entity_id,
    d.service_agreement_id AS service_agreement_id,
    d.external_id AS external_id,
    d.approval_id AS approval_id,
    d.active_party_id AS active_party_id,
    d.import_id AS import_id,
    d.user_reference AS user_reference,
    d.contact_reference AS contact_reference,
    d.searchable_field_one AS searchable_field_one,
    d.searchable_field_two AS searchable_field_two,
    d.created_at AS created_at,
    d.updated_at AS updated_at,
    d.additions AS additions,
    d.address_line1 AS address_line1,
    d.address_line2 AS address_line2,
    d.street_name AS street_name,
    d.town AS town,
    d.country AS country,
    d.post_code AS post_code,
    d.country_sub_division AS country_sub_division
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_party_other') t
    ON t.party_hashkey = d.party_hashkey AND t.hashdiff = d.hd_party_other;

DROP TEMPORARY TABLE IF EXISTS tmp_party;
