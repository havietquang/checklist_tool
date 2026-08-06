{{ config(
    alias = 'link_money_market_dept_acct_officer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_money_market_dept_acct_officer_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'money_market', 'phase1', 'all']
) }}

{% set source_model = 'v_stg_t24_t24_money_market' %}
{% set source_name = 't24' %}
{% set source_table = 't24_money_market' %}
{% set unique_key = 'link_money_market_dept_acct_officer_hashkey' %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = ['id', 't_mm_officer'],
    foreign_business_key_cols = {
        'money_market_hashkey': ['id'],
        'dept_acct_officer_hashkey': ['t_mm_officer']
    }
) }}

