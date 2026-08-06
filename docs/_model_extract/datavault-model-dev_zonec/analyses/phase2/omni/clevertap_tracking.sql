-- Source: omni.clevertap_tracking | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_clevertap_tracking; CREATE TEMPORARY TABLE tmp_clevertap_tracking AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS clevertap_tracking_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(clevertap_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(event_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(channel AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(modified_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cif AS string))), ''), 256) AS hd_clevertap_tracking_detail,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id, clevertap_id, event_name, channel, created_at, modified_at, cif
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.clevertap_tracking')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}}
  AND id IS NOT NULL;

-- HUB clevertap_tracking
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_clevertap_tracking')
(clevertap_tracking_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (
    SELECT * FROM tmp_clevertap_tracking
    QUALIFY ROW_NUMBER() OVER (PARTITION BY clevertap_tracking_hashkey ORDER BY data_date) = 1
)
SELECT
    d.clevertap_tracking_hashkey AS clevertap_tracking_hashkey,
    CAST(d.id AS STRING) AS business_key,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__clevertap_tracking' AS record_source
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_clevertap_tracking') t
    ON t.clevertap_tracking_hashkey = d.clevertap_tracking_hashkey;

-- SAT clevertap_tracking_detail
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_clevertap_tracking_detail')
(clevertap_tracking_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 clevertap_id, event_name, channel, created_at, modified_at, cif)
WITH deduped AS (
    SELECT * FROM tmp_clevertap_tracking
    QUALIFY ROW_NUMBER() OVER (PARTITION BY clevertap_tracking_hashkey, hd_clevertap_tracking_detail ORDER BY data_date) = 1
)
SELECT
    d.clevertap_tracking_hashkey AS clevertap_tracking_hashkey,
    d.hd_clevertap_tracking_detail AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__clevertap_tracking' AS record_source,
    d.clevertap_id AS clevertap_id,
    d.event_name AS event_name,
    d.channel AS channel,
    d.created_at AS created_at,
    d.modified_at AS modified_at,
    d.cif AS cif
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_clevertap_tracking_detail') t
    ON t.clevertap_tracking_hashkey = d.clevertap_tracking_hashkey AND t.hashdiff = d.hd_clevertap_tracking_detail;

-- LINK link_clevertap_tracking_customer
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_clevertap_tracking_customer')
(link_clevertap_tracking_customer_hashkey, clevertap_tracking_hashkey, customer_hashkey,
 source_event_date, load_timestamp, record_source)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(cif AS string))), ''), 256) AS link_clevertap_tracking_customer_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS clevertap_tracking_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(cif AS string))), ''), 256) AS customer_hashkey,
        source_event_date
    FROM tmp_clevertap_tracking
    WHERE cif IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id, cif ORDER BY data_date) = 1
)
SELECT
    d.link_clevertap_tracking_customer_hashkey AS link_clevertap_tracking_customer_hashkey,
    d.clevertap_tracking_hashkey AS clevertap_tracking_hashkey,
    d.customer_hashkey AS customer_hashkey,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__clevertap_tracking' AS record_source
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_clevertap_tracking_customer') t
    ON t.link_clevertap_tracking_customer_hashkey = d.link_clevertap_tracking_customer_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_clevertap_tracking;
