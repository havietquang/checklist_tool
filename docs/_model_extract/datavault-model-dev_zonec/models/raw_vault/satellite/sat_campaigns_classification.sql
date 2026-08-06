/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
incremental_strategy: 'merge' = upsert theo unique_key
unique_key          : Khoa dinh danh record
skip_matched_step   : true = bo record khong doi -> tang performance
tags                : ['clevertap'] = filter khi run (dbt run --select tag:clevertap)
====================================================================
*/

{{ config(
    alias = 'sat_campaigns_classification',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['campaigns_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['clevertap', 'campaign', 'phase2', 'all']
) }}

{% set source_name = 'clevertap' %}
{% set source_table = 'campaigns' %}
{% set hashdiff_col = 'hashdiff_campaigns_classification' %}
{% set hub_hashkey = 'campaigns_hashkey' %}
{% set source_model = 'v_stg_clevertap_campaigns' %}
{% set list_cols = ['sent_influenced_conversions_pct AS sent_influenced_conversions_pct','title AS title','message AS message','start_date AS start_date','start_time AS start_time','device AS device','who_query AS who_query','constant_property AS constant_property','safety_check_limit AS safety_check_limit','campaign_per_day_limit AS campaign_per_day_limit','reach AS reach','created_by AS created_by','created_time AS created_time','labels AS labels','total_delivered_users AS total_delivered_users','total_unsubscribes100 AS total_unsubscribes100','ios_badge_count AS ios_badge_count','ios_deep_link AS ios_deep_link','ios_mutable_content AS ios_mutable_content','android_summary AS android_summary','android_large_icon_url AS android_large_icon_url','android_small_app_icon_colour AS android_small_app_icon_colour','android_sound_file AS android_sound_file','android_notification_tray_priority AS android_notification_tray_priority','android_notification_delivery_priority AS android_notification_delivery_priority','notification_channels AS notification_channels','badge_icon AS badge_icon','send_to_app_inbox_as_well AS send_to_app_inbox_as_well','service_provider AS service_provider','conversion_event AS conversion_event','conversion_time_in_minutes AS conversion_time_in_minutes','campaign_url AS campaign_url','push_amplification_applied AS push_amplification_applied','web_priority AS web_priority','time_to_live_type AS time_to_live_type','time_to_live_value AS time_to_live_value','template_name AS template_name','provider_name AS provider_name','waba_number AS waba_number','total_control_group_count AS total_control_group_count','total_control_group_conversions_pct AS total_control_group_conversions_pct','revenue_within_conversion_time AS revenue_within_conversion_time','system_control_group_conversions_pct AS system_control_group_conversions_pct','system_control_group_revenue AS system_control_group_revenue','campaign_control_group_count AS campaign_control_group_count','campaign_control_group_conversions_pct AS campaign_control_group_conversions_pct','campaign_control_group_revenue AS campaign_control_group_revenue','custom_control_group_count AS custom_control_group_count','custom_control_group_conversions_pct AS custom_control_group_conversions_pct','custom_control_group_revenue AS custom_control_group_revenue','custom_control_group_name AS custom_control_group_name','sent_influenced_revenue AS sent_influenced_revenue','total_html_viewed_events AS total_html_viewed_events','total_amp_viewed_events AS total_amp_viewed_events','total_html_clicked_events AS total_html_clicked_events','total_amp_clicked_events AS total_amp_clicked_events','campaign_name AS campaign_name','channel AS channel','delivery AS delivery','type AS type','variant AS variant','os AS os','dnd AS dnd','timezone AS timezone','cutoff AS cutoff','fcap AS fcap','throttle AS throttle','campaign_overall_limit AS campaign_overall_limit','end_date AS end_date','total_delivered_events AS total_delivered_events','total_unsubscribes78 AS total_unsubscribes78','ios_rich_media_type AS ios_rich_media_type','ios_rich_media_url AS ios_rich_media_url','ios_sound_file AS ios_sound_file','ios_category AS ios_category','android_subtitle AS android_subtitle','android_image_url AS android_image_url','android_deep_link AS android_deep_link','collapse_notification AS collapse_notification','badge_id AS badge_id','rendermax_enabled AS rendermax_enabled','click_through_conversion_revenue AS click_through_conversion_revenue','total_control_group_conversions AS total_control_group_conversions','total_control_group_revenue AS total_control_group_revenue','influenced_revenue AS influenced_revenue','system_control_group_count AS system_control_group_count','system_control_group_conversions AS system_control_group_conversions','campaign_control_group_conversions AS campaign_control_group_conversions','custom_control_group_conversions AS custom_control_group_conversions','sent_influenced_conversions AS sent_influenced_conversions','total_html_unsubscribes AS total_html_unsubscribes','total_amp_unsubscribes AS total_amp_unsubscribes'] %}
{% set raw_sql = None %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
