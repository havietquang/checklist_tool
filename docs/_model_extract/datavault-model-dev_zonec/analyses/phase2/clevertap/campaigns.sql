-- Source  : .clevertap.campaigns
-- Targets : hub_campaigns
--           sts_hub_campaigns
--           sat_campaigns_information
--           sat_campaigns_classification
-- Range   : 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_campaigns; CREATE TEMPORARY TABLE tmp_campaigns AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(campaign_id AS string))), ''), 256) AS campaigns_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(total_sent_events                       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_clicked_users                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_viewed_users                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_viewed_events                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_clicked_events                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(unique_sent_users                       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(unique_viewed_within_conversion_time    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(unique_clicked_within_conversion_time   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(error_user_not_reachable                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(error_push_unregistered_android         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(influenced_conversions_pct              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(influenced_conversions                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(error_user_dnd                          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(click_through_conversions_pct           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_sent_users                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(error_apns_bad_device_token             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(estimated_reach                         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(click_through_conversions               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(unique_converted_within_conversion_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(errors                                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(status                                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(error_inbox_ttl_expired                 AS string))), ''), 256) AS hd_campaigns_information,
    sha2(COALESCE(UPPER(TRIM(CAST(sent_influenced_conversions_pct        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(title                                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(message                                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(start_date                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(start_time                             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(device                                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(who_query                              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(constant_property                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(safety_check_limit                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(campaign_per_day_limit                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(reach                                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_by                             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_time                           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(labels                                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_delivered_users                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_unsubscribes100                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ios_badge_count                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ios_deep_link                          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ios_mutable_content                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(android_summary                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(android_large_icon_url                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(android_small_app_icon_colour          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(android_sound_file                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(android_notification_tray_priority     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(android_notification_delivery_priority AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(notification_channels                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(badge_icon                             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(send_to_app_inbox_as_well              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(service_provider                       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(conversion_event                       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(conversion_time_in_minutes             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(campaign_url                           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(push_amplification_applied             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(web_priority                           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(time_to_live_type                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(time_to_live_value                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(template_name                          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(provider_name                          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(waba_number                            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_control_group_count              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_control_group_conversions_pct    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(revenue_within_conversion_time         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(system_control_group_conversions_pct   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(system_control_group_revenue           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(campaign_control_group_count           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(campaign_control_group_conversions_pct AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(campaign_control_group_revenue         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(custom_control_group_count             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(custom_control_group_conversions_pct   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(custom_control_group_revenue           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(custom_control_group_name              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sent_influenced_revenue                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_html_viewed_events               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_amp_viewed_events                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_html_clicked_events              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_amp_clicked_events               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(campaign_name                          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(channel                                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(delivery                               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(type                                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(variant                                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(os                                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dnd                                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(timezone                               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cutoff                                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(fcap                                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(throttle                               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(campaign_overall_limit                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(end_date                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_delivered_events                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_unsubscribes78                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ios_rich_media_type                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ios_rich_media_url                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ios_sound_file                         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ios_category                           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(android_subtitle                       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(android_image_url                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(android_deep_link                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(collapse_notification                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(badge_id                               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rendermax_enabled                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(click_through_conversion_revenue       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_control_group_conversions        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_control_group_revenue            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(influenced_revenue                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(system_control_group_count             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(system_control_group_conversions       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(campaign_control_group_conversions     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(custom_control_group_conversions       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sent_influenced_conversions            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_html_unsubscribes                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_amp_unsubscribes                 AS string))), ''), 256) AS hd_campaigns_classification,
    data_date,
    to_date(date_format(cast(try_to_timestamp(run_date, 'M/d/yyyy') as date), 'yyyyMMdd'), 'yyyyMMdd') AS source_event_date,
    campaign_id,
    campaign_name, channel, os, device, start_date, start_time, end_date, status, created_by, created_time,
    labels, delivery, type, variant, title, message, who_query, constant_property, badge_id,
    badge_icon, send_to_app_inbox_as_well, service_provider, conversion_event, conversion_time_in_minutes,
    campaign_url, template_name, provider_name, waba_number, estimated_reach, reach,
    total_sent_users, total_viewed_users, total_clicked_users, total_delivered_users,
    total_sent_events, total_viewed_events, total_clicked_events, total_delivered_events, errors,
    unique_sent_users, click_through_conversions, click_through_conversions_pct,
    click_through_conversion_revenue, unique_viewed_within_conversion_time,
    unique_clicked_within_conversion_time, unique_converted_within_conversion_time,
    revenue_within_conversion_time, influenced_conversions, influenced_conversions_pct,
    influenced_revenue, total_unsubscribes78, total_unsubscribes100,
    sent_influenced_conversions, sent_influenced_conversions_pct, sent_influenced_revenue,
    total_html_viewed_events, total_amp_viewed_events, total_html_clicked_events,
    total_amp_clicked_events, total_html_unsubscribes, total_amp_unsubscribes,
    dnd, timezone, cutoff, fcap, throttle, campaign_overall_limit, safety_check_limit,
    campaign_per_day_limit, collapse_notification, notification_channels,
    push_amplification_applied, web_priority, time_to_live_type, time_to_live_value,
    rendermax_enabled, ios_rich_media_type, ios_rich_media_url, ios_sound_file, ios_badge_count,
    ios_category, ios_deep_link, ios_mutable_content, android_subtitle, android_image_url,
    android_summary, android_large_icon_url, android_small_app_icon_colour, android_deep_link,
    android_sound_file, android_notification_tray_priority, android_notification_delivery_priority,
    total_control_group_count, total_control_group_conversions, total_control_group_conversions_pct,
    total_control_group_revenue, system_control_group_count, system_control_group_conversions,
    system_control_group_conversions_pct, system_control_group_revenue,
    campaign_control_group_count, campaign_control_group_conversions,
    campaign_control_group_conversions_pct, campaign_control_group_revenue,
    custom_control_group_count, custom_control_group_conversions,
    custom_control_group_conversions_pct, custom_control_group_revenue, custom_control_group_name,
    error_apns_bad_device_token, error_user_not_reachable, error_inbox_ttl_expired,
    error_user_dnd, error_push_unregistered_android
FROM IDENTIFIER({{catalog_sourcing}} || '.clevertap.campaigns')
WHERE to_date(date_format(cast(try_to_timestamp(run_date, 'M/d/yyyy') as date), 'yyyyMMdd'), 'yyyyMMdd') BETWEEN to_date({{start_date}}, 'yyyyMMdd') AND to_date({{end_date}}, 'yyyyMMdd')
  AND campaign_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_campaigns')
(campaigns_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_campaigns QUALIFY ROW_NUMBER() OVER (PARTITION BY campaigns_hashkey ORDER BY data_date) = 1)
SELECT
    d.campaigns_hashkey AS campaigns_hashkey,
    CAST(d.campaign_id AS STRING) AS business_key,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'clevertap__campaigns' AS record_source
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_campaigns') t
    ON t.campaigns_hashkey = d.campaigns_hashkey;

-- [sts_hub_campaigns] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_campaigns')
(campaigns_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_campaigns
),
present_per_date AS (
    SELECT DISTINCT campaigns_hashkey, source_event_date FROM tmp_campaigns
),
full_timeline AS (
    SELECT DISTINCT h.campaigns_hashkey, d.source_event_date,
           CASE WHEN p.campaigns_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_campaigns') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.campaigns_hashkey = h.campaigns_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT campaigns_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY campaigns_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT campaigns_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_campaigns')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_campaigns)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY campaigns_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.campaigns_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.campaigns_hashkey = t.campaigns_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.campaigns_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.campaigns_hashkey = t.campaigns_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.campaigns_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_campaigns') t
    ON t.campaigns_hashkey = sc.campaigns_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_campaigns_information')
(campaigns_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 total_sent_events, total_clicked_users, total_viewed_users, total_viewed_events, total_clicked_events,
 unique_sent_users, unique_viewed_within_conversion_time, unique_clicked_within_conversion_time,
 error_user_not_reachable, error_push_unregistered_android, influenced_conversions_pct,
 influenced_conversions, error_user_dnd, click_through_conversions_pct, total_sent_users,
 error_apns_bad_device_token, estimated_reach, click_through_conversions,
 unique_converted_within_conversion_time, errors, status, error_inbox_ttl_expired)
WITH deduped AS (SELECT * FROM tmp_campaigns QUALIFY ROW_NUMBER() OVER (PARTITION BY campaigns_hashkey, hd_campaigns_information ORDER BY data_date) = 1)
SELECT
    d.campaigns_hashkey AS campaigns_hashkey,
    d.hd_campaigns_information AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'clevertap__campaigns' AS record_source,
    d.total_sent_events AS total_sent_events,
    d.total_clicked_users AS total_clicked_users,
    d.total_viewed_users AS total_viewed_users,
    d.total_viewed_events AS total_viewed_events,
    d.total_clicked_events AS total_clicked_events,
    d.unique_sent_users AS unique_sent_users,
    d.unique_viewed_within_conversion_time AS unique_viewed_within_conversion_time,
    d.unique_clicked_within_conversion_time AS unique_clicked_within_conversion_time,
    d.error_user_not_reachable AS error_user_not_reachable,
    d.error_push_unregistered_android AS error_push_unregistered_android,
    d.influenced_conversions_pct AS influenced_conversions_pct,
    d.influenced_conversions AS influenced_conversions,
    d.error_user_dnd AS error_user_dnd,
    d.click_through_conversions_pct AS click_through_conversions_pct,
    d.total_sent_users AS total_sent_users,
    d.error_apns_bad_device_token AS error_apns_bad_device_token,
    d.estimated_reach AS estimated_reach,
    d.click_through_conversions AS click_through_conversions,
    d.unique_converted_within_conversion_time AS unique_converted_within_conversion_time,
    d.errors AS errors,
    d.status AS status,
    d.error_inbox_ttl_expired AS error_inbox_ttl_expired
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_campaigns_information') t
    ON t.campaigns_hashkey = d.campaigns_hashkey AND t.hashdiff = d.hd_campaigns_information;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_campaigns_classification')
(campaigns_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 sent_influenced_conversions_pct, title, message, start_date, start_time, device, who_query,
 constant_property, safety_check_limit, campaign_per_day_limit, reach, created_by, created_time, labels,
 total_delivered_users, total_unsubscribes100, ios_badge_count, ios_deep_link, ios_mutable_content,
 android_summary, android_large_icon_url, android_small_app_icon_colour, android_sound_file,
 android_notification_tray_priority, android_notification_delivery_priority, notification_channels,
 badge_icon, send_to_app_inbox_as_well, service_provider, conversion_event, conversion_time_in_minutes,
 campaign_url, push_amplification_applied, web_priority, time_to_live_type, time_to_live_value,
 template_name, provider_name, waba_number, total_control_group_count, total_control_group_conversions_pct,
 revenue_within_conversion_time, system_control_group_conversions_pct, system_control_group_revenue,
 campaign_control_group_count, campaign_control_group_conversions_pct, campaign_control_group_revenue,
 custom_control_group_count, custom_control_group_conversions_pct, custom_control_group_revenue,
 custom_control_group_name, sent_influenced_revenue, total_html_viewed_events, total_amp_viewed_events,
 total_html_clicked_events, total_amp_clicked_events, campaign_name, channel, delivery, type, variant, os,
 dnd, timezone, cutoff, fcap, throttle, campaign_overall_limit, end_date,
 total_delivered_events, total_unsubscribes78, ios_rich_media_type, ios_rich_media_url, ios_sound_file,
 ios_category, android_subtitle, android_image_url, android_deep_link, collapse_notification, badge_id,
 rendermax_enabled, click_through_conversion_revenue, total_control_group_conversions,
 total_control_group_revenue, influenced_revenue, system_control_group_count,
 system_control_group_conversions, campaign_control_group_conversions, custom_control_group_conversions,
 sent_influenced_conversions, total_html_unsubscribes, total_amp_unsubscribes)
WITH deduped AS (SELECT * FROM tmp_campaigns QUALIFY ROW_NUMBER() OVER (PARTITION BY campaigns_hashkey, hd_campaigns_classification ORDER BY data_date) = 1)
SELECT
    d.campaigns_hashkey AS campaigns_hashkey,
    d.hd_campaigns_classification AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'clevertap__campaigns' AS record_source,
    d.sent_influenced_conversions_pct AS sent_influenced_conversions_pct,
    d.title AS title,
    d.message AS message,
    d.start_date AS start_date,
    d.start_time AS start_time,
    d.device AS device,
    d.who_query AS who_query,
    d.constant_property AS constant_property,
    d.safety_check_limit AS safety_check_limit,
    d.campaign_per_day_limit AS campaign_per_day_limit,
    d.reach AS reach,
    d.created_by AS created_by,
    d.created_time AS created_time,
    d.labels AS labels,
    d.total_delivered_users AS total_delivered_users,
    d.total_unsubscribes100 AS total_unsubscribes100,
    d.ios_badge_count AS ios_badge_count,
    d.ios_deep_link AS ios_deep_link,
    d.ios_mutable_content AS ios_mutable_content,
    d.android_summary AS android_summary,
    d.android_large_icon_url AS android_large_icon_url,
    d.android_small_app_icon_colour AS android_small_app_icon_colour,
    d.android_sound_file AS android_sound_file,
    d.android_notification_tray_priority AS android_notification_tray_priority,
    d.android_notification_delivery_priority AS android_notification_delivery_priority,
    d.notification_channels AS notification_channels,
    d.badge_icon AS badge_icon,
    d.send_to_app_inbox_as_well AS send_to_app_inbox_as_well,
    d.service_provider AS service_provider,
    d.conversion_event AS conversion_event,
    d.conversion_time_in_minutes AS conversion_time_in_minutes,
    d.campaign_url AS campaign_url,
    d.push_amplification_applied AS push_amplification_applied,
    d.web_priority AS web_priority,
    d.time_to_live_type AS time_to_live_type,
    d.time_to_live_value AS time_to_live_value,
    d.template_name AS template_name,
    d.provider_name AS provider_name,
    d.waba_number AS waba_number,
    d.total_control_group_count AS total_control_group_count,
    d.total_control_group_conversions_pct AS total_control_group_conversions_pct,
    d.revenue_within_conversion_time AS revenue_within_conversion_time,
    d.system_control_group_conversions_pct AS system_control_group_conversions_pct,
    d.system_control_group_revenue AS system_control_group_revenue,
    d.campaign_control_group_count AS campaign_control_group_count,
    d.campaign_control_group_conversions_pct AS campaign_control_group_conversions_pct,
    d.campaign_control_group_revenue AS campaign_control_group_revenue,
    d.custom_control_group_count AS custom_control_group_count,
    d.custom_control_group_conversions_pct AS custom_control_group_conversions_pct,
    d.custom_control_group_revenue AS custom_control_group_revenue,
    d.custom_control_group_name AS custom_control_group_name,
    d.sent_influenced_revenue AS sent_influenced_revenue,
    d.total_html_viewed_events AS total_html_viewed_events,
    d.total_amp_viewed_events AS total_amp_viewed_events,
    d.total_html_clicked_events AS total_html_clicked_events,
    d.total_amp_clicked_events AS total_amp_clicked_events,
    d.campaign_name AS campaign_name,
    d.channel AS channel,
    d.delivery AS delivery,
    d.type AS type,
    d.variant AS variant,
    d.os AS os,
    d.dnd AS dnd,
    d.timezone AS timezone,
    d.cutoff AS cutoff,
    d.fcap AS fcap,
    d.throttle AS throttle,
    d.campaign_overall_limit AS campaign_overall_limit,
    d.end_date AS end_date,
    d.total_delivered_events AS total_delivered_events,
    d.total_unsubscribes78 AS total_unsubscribes78,
    d.ios_rich_media_type AS ios_rich_media_type,
    d.ios_rich_media_url AS ios_rich_media_url,
    d.ios_sound_file AS ios_sound_file,
    d.ios_category AS ios_category,
    d.android_subtitle AS android_subtitle,
    d.android_image_url AS android_image_url,
    d.android_deep_link AS android_deep_link,
    d.collapse_notification AS collapse_notification,
    d.badge_id AS badge_id,
    d.rendermax_enabled AS rendermax_enabled,
    d.click_through_conversion_revenue AS click_through_conversion_revenue,
    d.total_control_group_conversions AS total_control_group_conversions,
    d.total_control_group_revenue AS total_control_group_revenue,
    d.influenced_revenue AS influenced_revenue,
    d.system_control_group_count AS system_control_group_count,
    d.system_control_group_conversions AS system_control_group_conversions,
    d.campaign_control_group_conversions AS campaign_control_group_conversions,
    d.custom_control_group_conversions AS custom_control_group_conversions,
    d.sent_influenced_conversions AS sent_influenced_conversions,
    d.total_html_unsubscribes AS total_html_unsubscribes,
    d.total_amp_unsubscribes AS total_amp_unsubscribes
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_campaigns_classification') t
    ON t.campaigns_hashkey = d.campaigns_hashkey AND t.hashdiff = d.hd_campaigns_classification;

DROP TEMPORARY TABLE IF EXISTS tmp_campaigns;
