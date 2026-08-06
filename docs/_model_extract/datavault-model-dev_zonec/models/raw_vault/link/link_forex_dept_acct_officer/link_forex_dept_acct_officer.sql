{{ config(
    alias = 'link_forex_dept_acct_officer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_forex_dept_acct_officer_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'forex', 'phase1', 'all']
) }}

{% set source_model = 'v_stg_t24_t24_forex' %}
{% set source_name = 't24' %}
{% set source_table = 't24_forex' %}
{% set unique_key = 'link_forex_dept_acct_officer_hashkey' %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = ['id', 't_account_officer'],
    foreign_business_key_cols = {
        'forex_hashkey': ['id'],
        'dept_acct_officer_hashkey': ['t_account_officer']
    }
) }}

