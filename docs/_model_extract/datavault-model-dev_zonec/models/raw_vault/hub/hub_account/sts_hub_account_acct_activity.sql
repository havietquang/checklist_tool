-- depends_on: {{ ref('v_stg_t24_t24_acct_activity') }}
-- depends_on: {{ ref('hub_account') }}

{{ config(
    alias = 'sts_hub_account_acct_activity',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['account_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['t24', 'account', 'phase2', 'all']
) }}

{% set source_model = 'v_stg_t24_t24_acct_activity' %}
{% set source_name = 't24' %}
{% set source_table = 't24_acct_activity' %}
{% set unique_key = 'account_hashkey' %}
{% set source_business_key_cols = ["split_part(id, '-', 1)"] %}
{% set hub_model = 'hub_account' %}
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
