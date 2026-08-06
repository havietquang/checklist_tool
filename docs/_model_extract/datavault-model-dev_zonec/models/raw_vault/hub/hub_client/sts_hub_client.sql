-- depends_on: {{ ref('v_stg_way4_client') }}
-- depends_on: {{ ref('hub_client') }}

{{ config(
    alias = 'sts_hub_client',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['client_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['way4', 'entity', 'phase1', 'all']
) }}

{% set source_model = 'v_stg_way4_client' %}
{% set source_name = 'way4' %}
{% set source_table = 'ows_client' %}
{% set unique_key = 'client_hashkey' %}
{% set source_business_key_cols = ['id'] %}
{% set source_filter = "amnd_state = 'A'" %}
{% set hub_model = 'hub_client' %}
{% set source_event_date_dttype = 'yyyyMMdd' %}

{{ sts_hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = source_business_key_cols,
    source_filter = source_filter,
    hub_model = hub_model,
    source_event_date_dttype = source_event_date_dttype
) }}
