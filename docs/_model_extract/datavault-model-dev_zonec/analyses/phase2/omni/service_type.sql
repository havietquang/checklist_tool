-- Source: omni.service_type | Full load init (backfill: null date)
-- REF table: ref_omni_service_type (reference, không dùng hub)
DROP TEMPORARY TABLE IF EXISTS tmp_service_type; CREATE TEMPORARY TABLE tmp_service_type AS
SELECT
    sha2(('omni_service_type' || CAST(id || service_code AS string)), 256) AS Ref_hashkey,
    'omni_service_type' AS Ref_type,
    CAST(id || service_code AS string) AS Ref_code,
    CAST(service_name AS string) AS Ref_description,
    business_function_id,
    maximum_default_transaction_bound,
    minimum_default_transaction_bound,
    support_limit,
    payment_type,
    sha2(COALESCE(UPPER(TRIM(CAST(business_function_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(maximum_default_transaction_bound AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(minimum_default_transaction_bound AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(support_limit AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(payment_type AS string))), ''), 256) AS hashdiff_full,
    'omni__service_type' AS Record_source,
    to_date({{start_date}}, 'yyyyMMdd') AS source_event_date
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.service_type')
WHERE id IS NOT NULL;

-- REF service_type
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_omni_service_type')
(Ref_hashkey, Ref_type, Ref_code, Ref_description,
 business_function_id, maximum_default_transaction_bound, minimum_default_transaction_bound,
 support_limit, payment_type,
 hashdiff_full, Record_source, source_event_date, load_timestamp)
WITH deduped AS (
    SELECT * FROM tmp_service_type
    QUALIFY ROW_NUMBER() OVER (PARTITION BY Ref_hashkey, hashdiff_full ORDER BY 1) = 1
)
SELECT
    d.Ref_hashkey AS Ref_hashkey,
    d.Ref_type AS Ref_type,
    d.Ref_code AS Ref_code,
    d.Ref_description AS Ref_description,
    d.business_function_id AS business_function_id,
    d.maximum_default_transaction_bound AS maximum_default_transaction_bound,
    d.minimum_default_transaction_bound AS minimum_default_transaction_bound,
    d.support_limit AS support_limit,
    d.payment_type AS payment_type,
    d.hashdiff_full AS hashdiff_full,
    d.Record_source AS Record_source,
    d.source_event_date AS source_event_date,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_omni_service_type') t
    ON t.Ref_hashkey = d.Ref_hashkey AND t.hashdiff_full = d.hashdiff_full;

DROP TEMPORARY TABLE IF EXISTS tmp_service_type;
