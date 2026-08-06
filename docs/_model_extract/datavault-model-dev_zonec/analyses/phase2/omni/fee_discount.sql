-- Source: omni.fee_discount | Full load init (backfill: null)
-- REF table: ref_omni_fee_discount (reference, không dùng hub)
DROP TEMPORARY TABLE IF EXISTS tmp_fee_discount; CREATE TEMPORARY TABLE tmp_fee_discount AS
SELECT
    sha2(('omni_fee_discount' || CAST(id || code AS string)), 256) AS Ref_hashkey,
    'omni_fee_discount' AS Ref_type,
    CAST(id || code AS string) AS Ref_code,
    CAST(description AS string) AS Ref_description,
    created_at,
    created_by,
    updated_at,
    updated_by,
    discount_rate,
    end_at,
    name,
    start_at,
    status,
    fee_discount_type,
    fee_reduction_time,
    approved_by,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(description AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_by AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_by AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(discount_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(end_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(start_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(fee_discount_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(fee_reduction_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(approved_by AS string))), ''), 256) AS hashdiff_full,
    'omni__fee_discount' AS Record_source,
    to_date({{start_date}}, 'yyyyMMdd') AS source_event_date
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.fee_discount')
WHERE id IS NOT NULL;

-- REF fee_discount
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_omni_fee_discount')
(Ref_hashkey, Ref_type, Ref_code, Ref_description,
 created_at, created_by, updated_at, updated_by, discount_rate, end_at, name, start_at,
 status, fee_discount_type, fee_reduction_time, approved_by,
 hashdiff_full, Record_source, source_event_date, load_timestamp)
WITH deduped AS (
    SELECT * FROM tmp_fee_discount
    QUALIFY ROW_NUMBER() OVER (PARTITION BY Ref_hashkey, hashdiff_full ORDER BY 1) = 1
)
SELECT
    d.Ref_hashkey AS Ref_hashkey,
    d.Ref_type AS Ref_type,
    d.Ref_code AS Ref_code,
    d.Ref_description AS Ref_description,
    d.created_at AS created_at,
    d.created_by AS created_by,
    d.updated_at AS updated_at,
    d.updated_by AS updated_by,
    d.discount_rate AS discount_rate,
    d.end_at AS end_at,
    d.name AS name,
    d.start_at AS start_at,
    d.status AS status,
    d.fee_discount_type AS fee_discount_type,
    d.fee_reduction_time AS fee_reduction_time,
    d.approved_by AS approved_by,
    d.hashdiff_full AS hashdiff_full,
    d.Record_source AS Record_source,
    d.source_event_date AS source_event_date,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_omni_fee_discount') t
    ON t.Ref_hashkey = d.Ref_hashkey AND t.hashdiff_full = d.hashdiff_full;

DROP TEMPORARY TABLE IF EXISTS tmp_fee_discount;
