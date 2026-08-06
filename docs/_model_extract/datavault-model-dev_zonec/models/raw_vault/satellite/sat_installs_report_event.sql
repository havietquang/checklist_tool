{{ config(
    alias = 'sat_installs_report_event',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['appsflyer_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['appsflyer', 'installs_report', 'phase2', 'all']
) }}

{% set source_name = 'appsflyer' %}
{% set source_table = 'installs_report' %}
{% set hashdiff_col = 'hashdiff_installs_report_event' %}
{% set hub_hashkey = 'appsflyer_hashkey' %}
{% set source_model = 'v_stg_appsflyer_installs_report' %}
{% set list_cols = ['install_time', 'event_time', 'event_name', 'event_value', 'event_revenue', 'event_revenue_currency', 'event_revenue_usd', 'event_source', 'is_receipt_validated', 'attributed_touch_type', 'attributed_touch_time', 'partner', 'media_source', 'channel', 'keywords', 'campaign', 'campaign_id', 'adset', 'adset_id', 'ad', 'ad_id', 'ad_type', 'site_id', 'sub_site_id', 'sub_param_1', 'sub_param_2', 'sub_param_3', 'sub_param_4', 'sub_param_5', 'carrier', 'cost_model', 'cost_value', 'cost_currency', 'contributor_1_partner', 'contributor_1_media_source', 'contributor_1_campaign', 'contributor_1_touch_type', 'contributor_1_touch_time', 'contributor_2_partner', 'contributor_2_media_source', 'contributor_2_campaign', 'contributor_2_touch_type', 'contributor_2_touch_time', 'contributor_3_partner', 'contributor_3_media_source', 'contributor_3_campaign', 'contributor_3_touch_type', 'contributor_3_touch_time', 'is_retargeting', 'retargeting_conversion_type', 'attribution_lookback', 'reengagement_window', 'is_primary_attribution']

 %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}

