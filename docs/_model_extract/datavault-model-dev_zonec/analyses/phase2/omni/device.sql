-- Source: omni.device | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_device; CREATE TEMPORARY TABLE tmp_device AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(device_id AS string))), ''), 256) AS device_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(friendly_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(vendor AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(model AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_date_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_date_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(platform AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(push_token AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dbs_user_id AS string))), ''), 256) AS hd_device_omni_information,
    CAST(CAST(LEAST(CAST(updated_date_time AS BIGINT), CAST(created_date_time AS BIGINT)) AS TIMESTAMP) AS DATE) AS source_event_date,
    device_id, friendly_name, vendor, model, created_date_time, updated_date_time,
    status, platform, push_token, dbs_user_id
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.device')
WHERE CAST(CAST(LEAST(CAST(updated_date_time AS BIGINT), CAST(created_date_time AS BIGINT)) AS TIMESTAMP) AS DATE) BETWEEN to_date({{start_date}}, 'yyyyMMdd') AND to_date({{end_date}}, 'yyyyMMdd')
  AND device_id IS NOT NULL;

-- SAT device_omni_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_device_omni_information')
(device_omni_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 friendly_name, vendor, model, created_date_time, updated_date_time, status, platform, push_token, dbs_user_id)
WITH deduped AS (
    SELECT * FROM tmp_device
    QUALIFY ROW_NUMBER() OVER (PARTITION BY device_hashkey, hd_device_omni_information ORDER BY source_event_date) = 1
)
SELECT
    d.device_hashkey AS device_omni_hashkey,
    d.hd_device_omni_information AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__device' AS record_source,
    d.friendly_name AS friendly_name,
    d.vendor AS vendor,
    d.model AS model,
    d.created_date_time AS created_date_time,
    d.updated_date_time AS updated_date_time,
    d.status AS status,
    d.platform AS platform,
    d.push_token AS push_token,
    d.dbs_user_id AS dbs_user_id
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_device_omni_information') t
    ON t.device_omni_hashkey = d.device_hashkey AND t.hashdiff = d.hd_device_omni_information;

DROP TEMPORARY TABLE IF EXISTS tmp_device;
