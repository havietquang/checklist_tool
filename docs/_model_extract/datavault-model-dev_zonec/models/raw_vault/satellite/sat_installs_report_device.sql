{{ config(
    alias = 'sat_installs_report_device',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['appsflyer_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['appsflyer', 'installs_report', 'phase2', 'all']
) }} 

{% set source_name = 'appsflyer' %}
{% set source_table = 'installs_report' %}
{% set hashdiff_col = 'hashdiff_installs_report_device' %}
{% set hub_hashkey = 'appsflyer_hashkey' %}
{% set source_model = 'v_stg_appsflyer_installs_report' %}
{% set list_cols = ['city', 'wifi', 'operator', 'language', 'advertising_id', 'idfa', 'android_id', 'customer_user_id', 'imei', 'idfv', 'platform', 'device_type', 'os_version', 'app_version', 'sdk_version', 'app_id', 'app_name', 'bundle_id', 'country_code', 'dma', 'ip', 'postal_code', 'region', 'state', 'user_agent', 'http_referrer', 'original_url']
%}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}

