-- depends_on: {{ ref('v_stg_t24_t24_lmm_account_balances') }}
-- depends_on: {{ ref('hub_loans') }}

{{ config(
    alias = 'sts_hub_loans_lmm_account_balances',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['loans_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['t24', 'loan', 'phase1', 'all']
) }}

{% set source_model = 'v_stg_t24_t24_lmm_account_balances' %}
{% set source_name = 't24' %}
{% set source_table = 't24_lmm_account_balances' %}
{% set unique_key = 'loans_hashkey' %}
{% set source_business_key_cols = ['id'] %}
{% set source_filter = "id like 'LD%'" %}
{% set hub_model = 'hub_loans' %}
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
