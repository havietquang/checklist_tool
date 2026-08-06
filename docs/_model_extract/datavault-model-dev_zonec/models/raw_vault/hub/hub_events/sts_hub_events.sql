-- depends_on: {{ ref('v_stg_clevertap_events') }}
-- depends_on: {{ ref('hub_events') }}

{{ config(
    alias = 'sts_hub_events',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['events_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['clevertap', 'event', 'phase2', 'all']
) }}

{% set source_model = 'v_stg_clevertap_events' %}
{% set source_name = 'clevertap' %}
{% set source_table = 'events' %}
{% set unique_key = 'events_hashkey' %}
{% set source_business_key_cols = ['CAST(ts AS string)', 'eventName', 'eventProps', 'profile:identity'] %}
{% set hub_model = 'hub_events' %}
{% set source_event_date_dttype = 'str+date' %}

{{ sts_hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = source_business_key_cols,
    hub_model = hub_model,
    source_event_date_dttype = source_event_date_dttype
) }}
