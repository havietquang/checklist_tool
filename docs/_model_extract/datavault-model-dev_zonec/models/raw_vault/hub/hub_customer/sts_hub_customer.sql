-- depends_on: {{ ref('v_stg_t24_t24_customer') }}
-- depends_on: {{ ref('hub_customer') }}

{{ config(
    alias = 'sts_hub_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['customer_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['t24', 'entity', 'phase1', 'all', 'bv_zonec']
) }}

{% set source_model = 'v_stg_t24_t24_customer' %}
{% set source_name = 't24' %}
{% set source_table = 't24_customer' %}
{% set unique_key = 'customer_hashkey' %}
{% set source_business_key_cols = ['id'] %}
{% set hub_model = 'hub_customer' %}
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

