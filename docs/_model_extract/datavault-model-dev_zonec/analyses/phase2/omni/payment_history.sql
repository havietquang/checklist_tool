-- Source: omni.payment_history | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_payment_history; CREATE TEMPORARY TABLE tmp_payment_history AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS payment_history_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(description AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(payment_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(amount AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(to_account_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(to_card_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_reference_id AS string))), ''), 256) AS hd_payment_history_information,
    sha2(COALESCE(UPPER(TRIM(CAST(detail_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(arrangement_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(core_counter_party_bank_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(counter_party_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_branch AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_province AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(modified_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_by AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(modified_by AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(additions AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(prop1 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(prop2 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(prop3 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(prop4 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(prop5 AS string))), ''), 256) AS hd_payment_history_other,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id, description, payment_type, status, amount, to_account_number, to_card_number, bank_reference_id,
    detail_code, arrangement_id, core_counter_party_bank_id, counter_party_name, bank_branch, bank_province,
    created_at, modified_at, created_by, modified_by, additions, prop1, prop2, prop3, prop4, prop5
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.payment_history')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}}
  AND id IS NOT NULL;

-- SAT payment_history_other
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_payment_history_other')
(payment_history_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 detail_code, arrangement_id, core_counter_party_bank_id, counter_party_name, bank_branch, bank_province,
 created_at, modified_at, created_by, modified_by, additions, prop1, prop2, prop3, prop4, prop5)
WITH deduped AS (
    SELECT * FROM tmp_payment_history
    QUALIFY ROW_NUMBER() OVER (PARTITION BY payment_history_hashkey, hd_payment_history_other ORDER BY data_date) = 1
)
SELECT
    d.payment_history_hashkey AS payment_history_hashkey,
    d.hd_payment_history_other AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__payment_history' AS record_source,
    d.detail_code AS detail_code,
    d.arrangement_id AS arrangement_id,
    d.core_counter_party_bank_id AS core_counter_party_bank_id,
    d.counter_party_name AS counter_party_name,
    d.bank_branch AS bank_branch,
    d.bank_province AS bank_province,
    d.created_at AS created_at,
    d.modified_at AS modified_at,
    d.created_by AS created_by,
    d.modified_by AS modified_by,
    d.additions AS additions,
    d.prop1 AS prop1,
    d.prop2 AS prop2,
    d.prop3 AS prop3,
    d.prop4 AS prop4,
    d.prop5 AS prop5
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_payment_history_other') t
    ON t.payment_history_hashkey = d.payment_history_hashkey AND t.hashdiff = d.hd_payment_history_other;

DROP TEMPORARY TABLE IF EXISTS tmp_payment_history;
