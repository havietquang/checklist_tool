-- Source: omni.payment_order | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_payment_order; CREATE TEMPORARY TABLE tmp_payment_order AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS payment_order_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(pmt_mode AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(pmt_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(priority AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(role AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(entry_class AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(intra_legal_entity AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(remaining_occurrences AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(account_scheme AS string))), ''), 256) AS hd_payment_order_classification,
    sha2(COALESCE(UPPER(TRIM(CAST(account AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(amount AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(currency AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(orig_acc_currency AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(send_to_core_datetime AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(delivery_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rejection_reason AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(reason_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(reason_text AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(error_description AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(address_line1 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(address_line2 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(street_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(town AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(country_sub_division AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(post_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(country AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(arrangement_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ext_arrangement_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(service_agreement_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(additions AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(payment_setup_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(approval_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(payment_submission_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(confirmation_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bank_reference_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_by AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_by AS string))), ''), 256) AS hd_payment_order_information,
    sha2(COALESCE(UPPER(TRIM(CAST(requested_exec_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(start_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(end_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(frequency AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(every AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(when_execute AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(repetition AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(remaining_occurrences AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(non_working_day_strategy AS string))), ''), 256) AS hd_payment_order_schedule,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id, status, bank_status, pmt_mode, pmt_type, priority, role, entry_class,
    intra_legal_entity, remaining_occurrences, account_scheme,
    account, name, amount, currency, orig_acc_currency, send_to_core_datetime, delivery_date,
    rejection_reason, reason_code, reason_text, error_description,
    address_line1, address_line2, street_name, town, country_sub_division, post_code, country,
    arrangement_id, ext_arrangement_id, service_agreement_id, additions, payment_setup_id,
    approval_id, payment_submission_id, confirmation_id, bank_reference_id,
    created_at, created_by, updated_at, updated_by,
    requested_exec_date, start_date, end_date, frequency, every, when_execute,
    repetition, non_working_day_strategy
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.payment_order')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}}
  AND id IS NOT NULL;

-- SAT payment_order_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_payment_order_information')
(payment_order_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 account, name, amount, currency, orig_acc_currency, send_to_core_datetime, delivery_date,
 rejection_reason, reason_code, reason_text, error_description,
 address_line1, address_line2, street_name, town, country_sub_division, post_code, country,
 arrangement_id, ext_arrangement_id, service_agreement_id, additions, payment_setup_id,
 approval_id, payment_submission_id, confirmation_id, bank_reference_id,
 created_at, created_by, updated_at, updated_by)
WITH deduped AS (
    SELECT * FROM tmp_payment_order
    QUALIFY ROW_NUMBER() OVER (PARTITION BY payment_order_hashkey, hd_payment_order_information ORDER BY data_date) = 1
)
SELECT
    d.payment_order_hashkey AS payment_order_hashkey,
    d.hd_payment_order_information AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__payment_order' AS record_source,
    d.account AS account,
    d.name AS name,
    d.amount AS amount,
    d.currency AS currency,
    d.orig_acc_currency AS orig_acc_currency,
    d.send_to_core_datetime AS send_to_core_datetime,
    d.delivery_date AS delivery_date,
    d.rejection_reason AS rejection_reason,
    d.reason_code AS reason_code,
    d.reason_text AS reason_text,
    d.error_description AS error_description,
    d.address_line1 AS address_line1,
    d.address_line2 AS address_line2,
    d.street_name AS street_name,
    d.town AS town,
    d.country_sub_division AS country_sub_division,
    d.post_code AS post_code,
    d.country AS country,
    d.arrangement_id AS arrangement_id,
    d.ext_arrangement_id AS ext_arrangement_id,
    d.service_agreement_id AS service_agreement_id,
    d.additions AS additions,
    d.payment_setup_id AS payment_setup_id,
    d.approval_id AS approval_id,
    d.payment_submission_id AS payment_submission_id,
    d.confirmation_id AS confirmation_id,
    d.bank_reference_id AS bank_reference_id,
    d.created_at AS created_at,
    d.created_by AS created_by,
    d.updated_at AS updated_at,
    d.updated_by AS updated_by
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_payment_order_information') t
    ON t.payment_order_hashkey = d.payment_order_hashkey AND t.hashdiff = d.hd_payment_order_information;

-- SAT payment_order_schedule
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_payment_order_schedule')
(payment_order_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 requested_exec_date, start_date, end_date, frequency, every, when_execute,
 repetition, remaining_occurrences, non_working_day_strategy)
WITH deduped AS (
    SELECT * FROM tmp_payment_order
    WHERE pmt_mode = 'RECURRING'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY payment_order_hashkey, hd_payment_order_schedule ORDER BY data_date) = 1
)
SELECT
    d.payment_order_hashkey AS payment_order_hashkey,
    d.hd_payment_order_schedule AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__payment_order' AS record_source,
    d.requested_exec_date AS requested_exec_date,
    d.start_date AS start_date,
    d.end_date AS end_date,
    d.frequency AS frequency,
    d.every AS every,
    d.when_execute AS when_execute,
    d.repetition AS repetition,
    d.remaining_occurrences AS remaining_occurrences,
    d.non_working_day_strategy AS non_working_day_strategy
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_payment_order_schedule') t
    ON t.payment_order_hashkey = d.payment_order_hashkey AND t.hashdiff = d.hd_payment_order_schedule;

DROP TEMPORARY TABLE IF EXISTS tmp_payment_order;
