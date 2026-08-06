-- depends_on: {{ ref('v_stg_t24_t24_sc_trading_position') }}
-- depends_on: {{ ref('hub_sc_trading_position') }}

{{ config(
    alias = 'sts_hub_sc_trading_position',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['sc_trading_position_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['t24', 'security', 'phase2', 'phase1', 'all']
) }}

{% set source_model = 'v_stg_t24_t24_sc_trading_position' %}
{% set source_name = 't24' %}
{% set source_table = 't24_sc_trading_position' %}
{% set unique_key = 'sc_trading_position_hashkey' %}
{% set source_business_key_cols = ['id'] %}
{% set hub_model = 'hub_sc_trading_position' %}
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

