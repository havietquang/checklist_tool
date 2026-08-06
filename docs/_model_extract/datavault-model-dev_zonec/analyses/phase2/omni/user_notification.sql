-- Source: omni.user_notification | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_user_notification; CREATE TEMPORARY TABLE tmp_user_notification AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(un.id AS string))), ''), 256) AS user_notification_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(un.created_on AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.effective_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.severity_level AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.title AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.message AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ack.acknowledgement_code AS string))), ''), 256) AS hd_notification,
    sha2(COALESCE(UPPER(TRIM(CAST(un.uuid AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.management_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.legal_entity_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.target_group_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.link AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.valid_from AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.expires_on AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.origin AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.where_to AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.additions AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.route_data AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(un.service_agreement_id AS string))), ''), 256) AS hd_notification_information,
    un.data_date, to_date(un.data_date, 'yyyyMMdd') AS source_event_date,
    un.id, un.created_on, un.effective_date, un.severity_level, un.title, un.message, ack.acknowledgement_code,
    un.uuid, un.management_id, un.legal_entity_id, un.target_group_code, un.link, un.valid_from, un.expires_on,
    un.origin, un.where_to, un.additions, un.route_data, un.service_agreement_id,
    un.internal_user_id
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.user_notification') un
LEFT JOIN IDENTIFIER({{catalog_sourcing}} || '.omni.acknowledgement') ack
    ON un.internal_user_id = ack.internal_user_id AND ack.notification_id = un.id
WHERE un.data_date BETWEEN {{start_date}} AND {{end_date}}
  AND un.id IS NOT NULL;

-- SAT notification_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_notification_information')
(notification_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 uuid, management_id, legal_entity_id, target_group_code, link, valid_from, expires_on,
 origin, where_to, additions, route_data, service_agreement_id)
WITH deduped AS (
    SELECT * FROM tmp_user_notification
    QUALIFY ROW_NUMBER() OVER (PARTITION BY user_notification_hashkey, hd_notification_information ORDER BY data_date) = 1
)
SELECT
    d.user_notification_hashkey AS notification_hashkey,
    d.hd_notification_information AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__user_notification' AS record_source,
    d.uuid AS uuid,
    d.management_id AS management_id,
    d.legal_entity_id AS legal_entity_id,
    d.target_group_code AS target_group_code,
    d.link AS link,
    d.valid_from AS valid_from,
    d.expires_on AS expires_on,
    d.origin AS origin,
    d.where_to AS where_to,
    d.additions AS additions,
    d.route_data AS route_data,
    d.service_agreement_id AS service_agreement_id
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_notification_information') t
    ON t.notification_hashkey = d.user_notification_hashkey AND t.hashdiff = d.hd_notification_information;

DROP TEMPORARY TABLE IF EXISTS tmp_user_notification;
