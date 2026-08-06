-- Source: omni.transfer_bill_history | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_transfer_bill_history; CREATE TEMPORARY TABLE tmp_transfer_bill_history AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS transfer_bill_history_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(card_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(card_account_num AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(method AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(service_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(provider_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(description AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bill_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bill_item_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bill_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(consumption_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(modified_at AS string))), ''), 256) AS hd_transfer_bill_information,
    sha2(COALESCE(UPPER(TRIM(CAST(currency AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(amount AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(amount_per_month AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(quantity AS string))), ''), 256) AS hd_transfer_bill_amount,
    sha2(COALESCE(UPPER(TRIM(CAST(core_response AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(core_response_time AS string))), ''), 256) AS hd_transfer_bill_response,
    sha2(COALESCE(UPPER(TRIM(CAST(account_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(customer_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ft_trans_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(reference_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(client_trans_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_by AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(modified_by AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(additions AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(extras AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(prop1 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(prop2 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(prop3 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(prop4 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(prop5 AS string))), ''), 256) AS hd_transfer_bill_other,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id, card_number, card_account_num, method, service_code, provider_code, description,
    bill_code, bill_item_no, bill_type, status, consumption_id, created_at, modified_at,
    currency, amount, amount_per_month, quantity,
    core_response, core_response_time,
    account_name, customer_name, ft_trans_no, reference_id, client_trans_id,
    created_by, modified_by, additions, extras, prop1, prop2, prop3, prop4, prop5
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.transfer_bill_history')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}}
  AND id IS NOT NULL;

-- SAT transfer_bill_other
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_transfer_bill_other')
(transfer_bill_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 account_name, customer_name, ft_trans_no, reference_id, client_trans_id,
 created_by, modified_by, additions, extras, prop1, prop2, prop3, prop4, prop5)
WITH deduped AS (
    SELECT * FROM tmp_transfer_bill_history
    QUALIFY ROW_NUMBER() OVER (PARTITION BY transfer_bill_history_hashkey, hd_transfer_bill_other ORDER BY data_date) = 1
)
SELECT
    d.transfer_bill_history_hashkey AS transfer_bill_hashkey,
    d.hd_transfer_bill_other AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__transfer_bill_history' AS record_source,
    d.account_name AS account_name,
    d.customer_name AS customer_name,
    d.ft_trans_no AS ft_trans_no,
    d.reference_id AS reference_id,
    d.client_trans_id AS client_trans_id,
    d.created_by AS created_by,
    d.modified_by AS modified_by,
    d.additions AS additions,
    d.extras AS extras,
    d.prop1 AS prop1,
    d.prop2 AS prop2,
    d.prop3 AS prop3,
    d.prop4 AS prop4,
    d.prop5 AS prop5
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_transfer_bill_other') t
    ON t.transfer_bill_hashkey = d.transfer_bill_history_hashkey AND t.hashdiff = d.hd_transfer_bill_other;

DROP TEMPORARY TABLE IF EXISTS tmp_transfer_bill_history;
