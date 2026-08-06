-- Source: omni.device_detail JOIN omni.device | Range: 20250101 -> 20250131
-- Khớp model sat_device_detail (MAS): device_omni_hashkey & source_event_date lấy từ omni.device
-- thông qua JOIN trên device_id; hashdiff gồm cả ma_key.
DROP TEMPORARY TABLE IF EXISTS tmp_device_detail; CREATE TEMPORARY TABLE tmp_device_detail AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(a.device_id AS string))), ''), 256) AS device_omni_hashkey,
    CAST(b.id AS STRING) AS ma_key,
    sha2(COALESCE(UPPER(TRIM(CAST(CAST(b.id AS STRING) AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(b.nfc_enabled AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(b.omni_version AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(b.os_version AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(b.unique_device_id AS string))), ''), 256) AS hd_device_detail,
    CAST(CAST(LEAST(CAST(a.updated_date_time AS BIGINT), CAST(a.created_date_time AS BIGINT)) AS TIMESTAMP) AS DATE) AS source_event_date,
    b.nfc_enabled, b.omni_version, b.os_version, b.unique_device_id
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.device') a
JOIN IDENTIFIER({{catalog_sourcing}} || '.omni.device_detail') b
    ON a.device_id = b.device_id
WHERE CAST(CAST(LEAST(CAST(a.updated_date_time AS BIGINT), CAST(a.created_date_time AS BIGINT)) AS TIMESTAMP) AS DATE)
        BETWEEN to_date({{start_date}}, 'yyyyMMdd') AND to_date({{end_date}}, 'yyyyMMdd')
  AND b.id IS NOT NULL;

-- SAT device_detail
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_device_detail')
(device_omni_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, nfc_enabled, omni_version, os_version, unique_device_id)
WITH deduped AS (
    SELECT * FROM tmp_device_detail
    QUALIFY ROW_NUMBER() OVER (PARTITION BY device_omni_hashkey, ma_key, hd_device_detail ORDER BY 1) = 1
)
SELECT
    d.device_omni_hashkey AS device_omni_hashkey,
    d.hd_device_detail AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__device_detail' AS record_source,
    d.ma_key AS ma_key,
    d.nfc_enabled AS nfc_enabled,
    d.omni_version AS omni_version,
    d.os_version AS os_version,
    d.unique_device_id AS unique_device_id
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_device_detail') t
    ON t.device_omni_hashkey = d.device_omni_hashkey AND t.ma_key = d.ma_key AND t.hashdiff = d.hd_device_detail;

DROP TEMPORARY TABLE IF EXISTS tmp_device_detail;
