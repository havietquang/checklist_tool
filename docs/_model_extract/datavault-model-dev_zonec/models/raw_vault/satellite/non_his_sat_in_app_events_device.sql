{{ config(
    alias = 'non_his_sat_in_app_events_device',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['source_event_date'],
    skip_matched_step = false,
    tags = ['appsflyer', 'in_app_events_report', 'phase2', 'all']
) }}

{% set source_name = 'appsflyer' %}
{% set source_table = 'in_app_events_report' %}
{% set hub_hashkey = 'appsflyer_hashkey' %}
{% set source_model = 'v_stg_appsflyer_in_app_events_report' %}
{% set list_cols = ['city', 'wifi', 'operator', 'language', 'advertising_id', 'android_id', 'customer_user_id', 'imei', 'idfv', 'platform', 'device_type', 'os_version', 'app_version', 'sdk_version', 'app_id', 'app_name', 'bundle_id', 'country_code', 'dma', 'ip', 'postal_code', 'region', 'state', 'user_agent', 'http_referrer', 'original_url']

%}

{{ non_his_satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    list_cols=list_cols
) }}
