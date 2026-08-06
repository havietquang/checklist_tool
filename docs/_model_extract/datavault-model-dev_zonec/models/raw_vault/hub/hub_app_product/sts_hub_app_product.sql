-- depends_on: {{ ref('v_stg_comb_app_product') }}
-- depends_on: {{ ref('hub_app_product') }}

{{ config(
    alias = 'sts_hub_app_product',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['app_product_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['comb', 'zonec', 'all']
) }}

{% set source_model = 'v_stg_comb_app_product' %}
{% set source_name = 'comb' %}
{% set source_table = 'app_product' %}
{% set unique_key = 'app_product_hashkey' %}
{% set source_business_key_cols = ['productcode'] %}
{% set hub_model = 'hub_app_product' %}
{% set source_event_date_dttype = 'yyyyMMdd' %}

{{ sts_hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = source_business_key_cols,
    hub_model = hub_model,
    source_event_date_dttype = source_event_date_dttype
) }}
