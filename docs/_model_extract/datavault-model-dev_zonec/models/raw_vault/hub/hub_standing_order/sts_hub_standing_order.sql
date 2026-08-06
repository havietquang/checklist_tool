-- depends_on: {{ ref('v_stg_t24_t24_standing_order') }}
-- depends_on: {{ ref('hub_standing_order') }}

{{ config(
    alias = 'sts_hub_standing_order',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['standing_order_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['t24', 'transaction', 'phase2', 'all']
) }}

{% set source_model = 'v_stg_t24_t24_standing_order' %}
{% set source_name = 't24' %}
{% set source_table = 't24_standing_order' %}
{% set unique_key = 'standing_order_hashkey' %}
{% set source_business_key_cols = ['id'] %}
{% set hub_model = 'hub_standing_order' %}
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

