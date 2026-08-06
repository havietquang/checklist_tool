-- depends_on: {{ ref('v_stg_comb_next_payment_amount') }}
-- depends_on: {{ ref('hub_consumer_loan') }}

{{ config(
    alias = 'sts_hub_consumer_loan_next_payment_amount',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['consumer_loan_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['comb', 'zonec', 'all']
) }}

{% set source_model = 'v_stg_comb_next_payment_amount' %}
{% set source_name = 'comb' %}
{% set source_table = 'next_payment_amount' %}
{% set unique_key = 'consumer_loan_hashkey' %}
{% set source_business_key_cols = ['contractcode'] %}
{% set hub_model = 'hub_consumer_loan' %}
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
