-- Source: omni.message | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_message; CREATE TEMPORARY TABLE tmp_message AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS message_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(uuid AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(root_message_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(subject AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(body AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_body_html AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(category AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(important AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sender AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sender_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sent_date_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(read_receipt AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(deletable AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(read_only AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(content_repo_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(content_path AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(metric_dimensions AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(additions AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(recipient AS string))), ''), 256) AS hd_message_information,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id, uuid, root_message_id, subject, body, is_body_html, category, important,
    sender, sender_name, sent_date_time, read_receipt, deletable, read_only,
    content_repo_id, content_path, metric_dimensions, additions, recipient
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.message')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}}
  AND id IS NOT NULL;

-- HUB message
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_message')
(message_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (
    SELECT * FROM tmp_message
    QUALIFY ROW_NUMBER() OVER (PARTITION BY message_hashkey ORDER BY data_date) = 1
)
SELECT
    d.message_hashkey AS message_hashkey,
    CAST(d.id AS STRING) AS business_key,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__message' AS record_source
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_message') t
    ON t.message_hashkey = d.message_hashkey;

-- SAT message_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_message_information')
(message_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 uuid, root_message_id, subject, body, is_body_html, category, important,
 sender, sender_name, sent_date_time, read_receipt, deletable, read_only,
 content_repo_id, content_path, metric_dimensions, additions, recipient)
WITH deduped AS (
    SELECT * FROM tmp_message
    QUALIFY ROW_NUMBER() OVER (PARTITION BY message_hashkey, hd_message_information ORDER BY data_date) = 1
)
SELECT
    d.message_hashkey AS message_hashkey,
    d.hd_message_information AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__message' AS record_source,
    d.uuid AS uuid,
    d.root_message_id AS root_message_id,
    d.subject AS subject,
    d.body AS body,
    d.is_body_html AS is_body_html,
    d.category AS category,
    d.important AS important,
    d.sender AS sender,
    d.sender_name AS sender_name,
    d.sent_date_time AS sent_date_time,
    d.read_receipt AS read_receipt,
    d.deletable AS deletable,
    d.read_only AS read_only,
    d.content_repo_id AS content_repo_id,
    d.content_path AS content_path,
    d.metric_dimensions AS metric_dimensions,
    d.additions AS additions,
    d.recipient AS recipient
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_message_information') t
    ON t.message_hashkey = d.message_hashkey AND t.hashdiff = d.hd_message_information;

-- LINK link_message_user
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_message_user')
(link_message_user_hashkey, message_hashkey, omni_user_hashkey,
 source_event_date, load_timestamp, record_source)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(recipient AS string))), ''), 256) AS link_message_user_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS message_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(recipient AS string))), ''), 256) AS omni_user_hashkey,
        source_event_date
    FROM tmp_message
    WHERE recipient IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id, recipient ORDER BY data_date) = 1
)
SELECT
    d.link_message_user_hashkey AS link_message_user_hashkey,
    d.message_hashkey AS message_hashkey,
    d.omni_user_hashkey AS omni_user_hashkey,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__message' AS record_source
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_message_user') t
    ON t.link_message_user_hashkey = d.link_message_user_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_message;
