-- Source: omni.customer_data_sharing_consent | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_customer_data_sharing_consent; CREATE TEMPORARY TABLE tmp_customer_data_sharing_consent AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS data_sharing_consent_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(channel AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(partner_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(consent_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(os_info AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(device_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(user_agent AS string))), ''), 256) AS hd_data_sharing_consent_information,
    sha2(COALESCE(UPPER(TRIM(CAST(created_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tracking_schema AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tracking_item AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(additions AS string))), ''), 256) AS hd_data_sharing_consent_other,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id, channel, partner_code, consent_status, os_info, device_name, user_agent,
    created_at, updated_at, tracking_schema, tracking_item, additions
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.customer_data_sharing_consent')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}}
  AND id IS NOT NULL;

-- SAT data_sharing_consent_other
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_data_sharing_consent_other')
(data_sharing_consent_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 created_at, updated_at, tracking_schema, tracking_item, additions)
WITH deduped AS (
    SELECT * FROM tmp_customer_data_sharing_consent
    QUALIFY ROW_NUMBER() OVER (PARTITION BY data_sharing_consent_hashkey, hd_data_sharing_consent_other ORDER BY data_date) = 1
)
SELECT
    d.data_sharing_consent_hashkey AS data_sharing_consent_hashkey,
    d.hd_data_sharing_consent_other AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__customer_data_sharing_consent' AS record_source,
    d.created_at AS created_at,
    d.updated_at AS updated_at,
    d.tracking_schema AS tracking_schema,
    d.tracking_item AS tracking_item,
    d.additions AS additions
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_data_sharing_consent_other') t
    ON t.data_sharing_consent_hashkey = d.data_sharing_consent_hashkey AND t.hashdiff = d.hd_data_sharing_consent_other;

DROP TEMPORARY TABLE IF EXISTS tmp_customer_data_sharing_consent;
