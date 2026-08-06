-- Source: omni.account_information | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_account_information; CREATE TEMPORARY TABLE tmp_account_information AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(party_id AS string))), ''), 256) AS party_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(account_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(account_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(other_identifier AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bic AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(iban AS string))), ''), 256) AS hd_party_account_information,
    sha2(COALESCE(UPPER(TRIM(CAST(uuid AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(alias AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phone_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(email AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(external_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(party_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(additions AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_address_source AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_address_line1 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_address_line2 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_street_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_town AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_country AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_post_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_country_sub_division AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_holder_addr_line1 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_holder_addr_line2 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_holder_street_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_holder_town AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_holder_country AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_holder_post_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_holder_country_sub_div AS string))), ''), 256) AS hd_party_account_other,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    account_number, account_type, name, other_identifier, bank_name, bank_code, bic, iban,
    uuid, alias, phone_number, email, external_id, party_id, additions,
    bank_address_source, bank_address_line1, bank_address_line2, bank_street_name, bank_town,
    bank_country, bank_post_code, bank_country_sub_division,
    acc_holder_addr_line1, acc_holder_addr_line2, acc_holder_street_name, acc_holder_town,
    acc_holder_country, acc_holder_post_code, acc_holder_country_sub_div
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.account_information')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}}
  AND party_id IS NOT NULL;

-- SAT party_account_other
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_party_account_other')
(party_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 uuid, alias, phone_number, email, external_id, party_id, additions,
 bank_address_source, bank_address_line1, bank_address_line2, bank_street_name, bank_town,
 bank_country, bank_post_code, bank_country_sub_division,
 acc_holder_addr_line1, acc_holder_addr_line2, acc_holder_street_name, acc_holder_town,
 acc_holder_country, acc_holder_post_code, acc_holder_country_sub_div)
WITH deduped AS (
    SELECT * FROM tmp_account_information
    QUALIFY ROW_NUMBER() OVER (PARTITION BY party_hashkey, hd_party_account_other ORDER BY data_date) = 1
)
SELECT
    d.party_hashkey AS party_hashkey,
    d.hd_party_account_other AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__account_information' AS record_source,
    d.uuid AS uuid,
    d.alias AS alias,
    d.phone_number AS phone_number,
    d.email AS email,
    d.external_id AS external_id,
    d.party_id AS party_id,
    d.additions AS additions,
    d.bank_address_source AS bank_address_source,
    d.bank_address_line1 AS bank_address_line1,
    d.bank_address_line2 AS bank_address_line2,
    d.bank_street_name AS bank_street_name,
    d.bank_town AS bank_town,
    d.bank_country AS bank_country,
    d.bank_post_code AS bank_post_code,
    d.bank_country_sub_division AS bank_country_sub_division,
    d.acc_holder_addr_line1 AS acc_holder_addr_line1,
    d.acc_holder_addr_line2 AS acc_holder_addr_line2,
    d.acc_holder_street_name AS acc_holder_street_name,
    d.acc_holder_town AS acc_holder_town,
    d.acc_holder_country AS acc_holder_country,
    d.acc_holder_post_code AS acc_holder_post_code,
    d.acc_holder_country_sub_div AS acc_holder_country_sub_div
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_party_account_other') t
    ON t.party_hashkey = d.party_hashkey AND t.hashdiff = d.hd_party_account_other;

DROP TEMPORARY TABLE IF EXISTS tmp_account_information;
