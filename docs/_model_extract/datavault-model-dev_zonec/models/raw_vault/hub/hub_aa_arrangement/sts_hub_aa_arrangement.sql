-- depends_on: {{ ref('v_stg_t24_t24_aa_arrangement') }}
-- depends_on: {{ ref('hub_aa_arrangement') }}

{{ config(
    alias = 'sts_hub_aa_arrangement',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['aa_arrangement_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['t24', 'zonec', 'all']
) }}

{% set source_model = 'v_stg_t24_t24_aa_arrangement' %}
{% set source_name = 't24' %}
{% set source_table = 't24_aa_arrangement' %}
{% set unique_key = 'aa_arrangement_hashkey' %}
{% set source_business_key_cols = ['id'] %}
{% set hub_model = 'hub_aa_arrangement' %}
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
