-- Source: omni.voucher | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_voucher; CREATE TEMPORARY TABLE tmp_voucher AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(voucher_code AS string))), ''), 256) AS voucher_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(service_type_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(discount_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(discount_price AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(discount_percentage AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(max_discount AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(min_price_acceptable AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(refund_liability_account AS string))), ''), 256) AS hd_voucher_information,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_by AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_by AS string))), ''), 256) AS hd_voucher_other,
    LEAST(CAST(UPDATED_AT AS DATE), CAST(CREATED_AT AS DATE)) AS source_event_date,
    voucher_code, service_type_code, discount_type, discount_price, discount_percentage,
    max_discount, min_price_acceptable, refund_liability_account,
    id, created_at, updated_at, created_by, updated_by
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.voucher')
WHERE LEAST(CAST(UPDATED_AT AS DATE), CAST(CREATED_AT AS DATE)) BETWEEN to_date({{start_date}}, 'yyyyMMdd') AND to_date({{end_date}}, 'yyyyMMdd')
  AND voucher_code IS NOT NULL;

-- SAT voucher_other
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_voucher_other')
(voucher_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 id, created_at, updated_at, created_by, updated_by)
WITH deduped AS (
    SELECT * FROM tmp_voucher
    QUALIFY ROW_NUMBER() OVER (PARTITION BY voucher_hashkey, hd_voucher_other ORDER BY source_event_date) = 1
)
SELECT
    d.voucher_hashkey AS voucher_hashkey,
    d.hd_voucher_other AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__voucher' AS record_source,
    d.id AS id,
    d.created_at AS created_at,
    d.updated_at AS updated_at,
    d.created_by AS created_by,
    d.updated_by AS updated_by
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_voucher_other') t
    ON t.voucher_hashkey = d.voucher_hashkey AND t.hashdiff = d.hd_voucher_other;

DROP TEMPORARY TABLE IF EXISTS tmp_voucher;
