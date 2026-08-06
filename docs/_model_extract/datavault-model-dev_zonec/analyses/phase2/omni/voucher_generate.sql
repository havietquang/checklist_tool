-- Source: omni.voucher_generate | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_voucher_generate; CREATE TEMPORARY TABLE tmp_voucher_generate AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(voucher_serial_code AS string))), ''), 256) AS voucher_generate_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_show AS string))), ''), 256) AS hd_voucher_generate_information,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_by AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_by AS string))), ''), 256) AS hd_voucher_generate_other,
    LEAST(CAST(UPDATED_AT AS DATE), CAST(CREATED_AT AS DATE)) AS source_event_date,
    voucher_serial_code, status, is_show,
    id, created_at, updated_at, created_by, updated_by, voucher_campaign_id
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.voucher_generate')
WHERE LEAST(CAST(UPDATED_AT AS DATE), CAST(CREATED_AT AS DATE)) BETWEEN to_date({{start_date}}, 'yyyyMMdd') AND to_date({{end_date}}, 'yyyyMMdd')
  AND voucher_serial_code IS NOT NULL;

-- SAT voucher_generate_other
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_voucher_generate_other')
(voucher_generate_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 id, created_at, updated_at, created_by, updated_by)
WITH deduped AS (
    SELECT * FROM tmp_voucher_generate
    QUALIFY ROW_NUMBER() OVER (PARTITION BY voucher_generate_hashkey, hd_voucher_generate_other ORDER BY source_event_date) = 1
)
SELECT
    d.voucher_generate_hashkey AS voucher_generate_hashkey,
    d.hd_voucher_generate_other AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__voucher_generate' AS record_source,
    d.id AS id,
    d.created_at AS created_at,
    d.updated_at AS updated_at,
    d.created_by AS created_by,
    d.updated_by AS updated_by
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_voucher_generate_other') t
    ON t.voucher_generate_hashkey = d.voucher_generate_hashkey AND t.hashdiff = d.hd_voucher_generate_other;

-- LINK link_voucher_generate_voucher_campaign
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_voucher_generate_voucher_campaign')
(link_voucher_generate_voucher_campaign_hashkey, voucher_generate_hashkey, voucher_campaign_hashkey,
 source_event_date, load_timestamp, record_source)
WITH campaign_src AS (
    SELECT id, voucher_campaign_code
    FROM IDENTIFIER({{catalog_sourcing}} || '.omni.voucher_campaign')
    WHERE id IS NOT NULL AND voucher_campaign_code IS NOT NULL
),
src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(t1.voucher_serial_code AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t2.voucher_campaign_code AS string))), ''), 256) AS link_voucher_generate_voucher_campaign_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t1.voucher_serial_code AS string))), ''), 256) AS voucher_generate_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t2.voucher_campaign_code AS string))), ''), 256) AS voucher_campaign_hashkey,
        t1.source_event_date
    FROM tmp_voucher_generate t1
    JOIN campaign_src t2 ON t1.voucher_campaign_id = t2.id
    WHERE t1.voucher_campaign_id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY t1.voucher_serial_code, t2.voucher_campaign_code ORDER BY t1.source_event_date) = 1
)
SELECT
    d.link_voucher_generate_voucher_campaign_hashkey AS link_voucher_generate_voucher_campaign_hashkey,
    d.voucher_generate_hashkey AS voucher_generate_hashkey,
    d.voucher_campaign_hashkey AS voucher_campaign_hashkey,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__voucher_campaign' AS record_source
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_voucher_generate_voucher_campaign') t
    ON t.link_voucher_generate_voucher_campaign_hashkey = d.link_voucher_generate_voucher_campaign_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_voucher_generate;
