-- depends_on: {{ ref('v_stg_t24_t24_company') }}
-- depends_on: {{ ref('hub_branch') }}

{{ config(
    alias = 'sts_hub_branch',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['branch_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['t24', 'entity', 'phase1', 'all']
) }}

{% set source_model = 'v_stg_t24_t24_company' %}
{% set source_name = 't24' %}
{% set source_table = 't24_company' %}
{% set unique_key = 'branch_hashkey' %}
{% set source_business_key_cols = ['id'] %}
{% set hub_model = 'hub_branch' %}
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

