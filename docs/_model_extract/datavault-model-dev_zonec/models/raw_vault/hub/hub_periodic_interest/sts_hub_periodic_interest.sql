-- depends_on: {{ ref('v_stg_t24_t24_periodic_interest') }}
-- depends_on: {{ ref('hub_periodic_interest') }}

{{ config(
    alias = 'sts_hub_periodic_interest',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['periodic_interest_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['t24', 'currency', 'phase2', 'all']
) }}

{% set source_model = 'v_stg_t24_t24_periodic_interest' %}
{% set source_name = 't24' %}
{% set source_table = 't24_periodic_interest' %}
{% set unique_key = 'periodic_interest_hashkey' %}
{% set source_business_key_cols = ['id'] %}
{% set hub_model = 'hub_periodic_interest' %}
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

