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
    alias = 'sat_campaigns_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['campaigns_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['clevertap', 'campaign', 'phase2', 'all']
) }}

{% set source_name = 'clevertap' %}
{% set source_table = 'campaigns' %}
{% set hashdiff_col = 'hashdiff_campaigns_information' %}
{% set hub_hashkey = 'campaigns_hashkey' %}
{% set source_model = 'v_stg_clevertap_campaigns' %}
{% set list_cols = ['total_sent_events AS total_sent_events','total_clicked_users AS total_clicked_users','total_viewed_users AS total_viewed_users','total_viewed_events AS total_viewed_events','total_clicked_events AS total_clicked_events','unique_sent_users AS unique_sent_users','unique_viewed_within_conversion_time AS unique_viewed_within_conversion_time','unique_clicked_within_conversion_time AS unique_clicked_within_conversion_time','error_user_not_reachable AS error_user_not_reachable','error_push_unregistered_android AS error_push_unregistered_android','influenced_conversions_pct AS influenced_conversions_pct','influenced_conversions AS influenced_conversions','error_user_dnd AS error_user_dnd','click_through_conversions_pct AS click_through_conversions_pct','total_sent_users AS total_sent_users','error_apns_bad_device_token AS error_apns_bad_device_token','estimated_reach AS estimated_reach','click_through_conversions AS click_through_conversions','unique_converted_within_conversion_time AS unique_converted_within_conversion_time','errors AS errors','status AS status','error_inbox_ttl_expired AS error_inbox_ttl_expired'] %}
{% set raw_sql = None %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
