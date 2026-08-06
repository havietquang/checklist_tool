-- Source: omni.voucher_campaign | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_voucher_campaign; CREATE TEMPORARY TABLE tmp_voucher_campaign AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(voucher_campaign_code AS string))), ''), 256) AS voucher_campaign_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(voucher_campaign_description AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(effect_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(end_effect_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(limit_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(import_status AS string))), ''), 256) AS hd_voucher_campaign_information,
    sha2(COALESCE(UPPER(TRIM(CAST(max_quantity_use_voucher AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(current_used_voucher AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(number_generated AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(budget_limit AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(current_budget AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(refund_account AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(time_pending_refund AS string))), ''), 256) AS hd_voucher_campaign_limit,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_by AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_by AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(voucher_user_group_id AS string))), ''), 256) AS hd_voucher_campaign_other,
    LEAST(CAST(UPDATED_AT AS DATE), CAST(CREATED_AT AS DATE)) AS source_event_date,
    voucher_campaign_code, voucher_campaign_description, effect_date, end_effect_date,
    limit_date, import_status,
    max_quantity_use_voucher, current_used_voucher, number_generated, budget_limit,
    current_budget, refund_account, time_pending_refund,
    id, created_at, updated_at, created_by, updated_by, voucher_user_group_id, voucher_id
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.voucher_campaign')
WHERE LEAST(CAST(UPDATED_AT AS DATE), CAST(CREATED_AT AS DATE)) BETWEEN to_date({{start_date}}, 'yyyyMMdd') AND to_date({{end_date}}, 'yyyyMMdd')
  AND voucher_campaign_code IS NOT NULL;

-- SAT voucher_campaign_other
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_voucher_campaign_other')
(voucher_campaign_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 id, created_at, updated_at, created_by, updated_by, voucher_user_group_id)
WITH deduped AS (
    SELECT * FROM tmp_voucher_campaign
    QUALIFY ROW_NUMBER() OVER (PARTITION BY voucher_campaign_hashkey, hd_voucher_campaign_other ORDER BY source_event_date) = 1
)
SELECT
    d.voucher_campaign_hashkey AS voucher_campaign_hashkey,
    d.hd_voucher_campaign_other AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__voucher_campaign' AS record_source,
    d.id AS id,
    d.created_at AS created_at,
    d.updated_at AS updated_at,
    d.created_by AS created_by,
    d.updated_by AS updated_by,
    d.voucher_user_group_id AS voucher_user_group_id
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_voucher_campaign_other') t
    ON t.voucher_campaign_hashkey = d.voucher_campaign_hashkey AND t.hashdiff = d.hd_voucher_campaign_other;

-- LINK link_voucher_campaign
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_voucher_campaign')
(link_voucher_campaign_hashkey, voucher_campaign_hashkey, voucher_hashkey,
 source_event_date, load_timestamp, record_source)
WITH voucher_src AS (
    SELECT id, voucher_code
    FROM IDENTIFIER({{catalog_sourcing}} || '.omni.voucher')
    WHERE id IS NOT NULL AND voucher_code IS NOT NULL
),
src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(t1.voucher_campaign_code AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t2.voucher_code AS string))), ''), 256) AS link_voucher_campaign_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t1.voucher_campaign_code AS string))), ''), 256) AS voucher_campaign_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t2.voucher_code AS string))), ''), 256) AS voucher_hashkey,
        t1.source_event_date
    FROM tmp_voucher_campaign t1
    JOIN voucher_src t2 ON t1.voucher_id = t2.id
    WHERE t1.voucher_id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY t1.voucher_campaign_code, t2.voucher_code ORDER BY t1.source_event_date) = 1
)
SELECT
    d.link_voucher_campaign_hashkey AS link_voucher_campaign_hashkey,
    d.voucher_campaign_hashkey AS voucher_campaign_hashkey,
    d.voucher_hashkey AS voucher_hashkey,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__voucher_campaign' AS record_source
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_voucher_campaign') t
    ON t.link_voucher_campaign_hashkey = d.link_voucher_campaign_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_voucher_campaign;
