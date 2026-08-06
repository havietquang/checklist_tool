{{ config(
    alias = 'link_loans_dept_acct_officer_nvgt',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_loans_dept_acct_officer_nvgt_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'loan', 'phase1', 'all']
) }}

{% set source_model = 'v_stg_t24_t24_loans_and_deposits' %}
{% set source_name = 't24' %}
{% set source_table = 't24_loans_and_deposits' %}
{% set unique_key = 'link_loans_dept_acct_officer_nvgt_hashkey' %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = ['id', 't_ac_middleman'],
    foreign_business_key_cols = {
        'loans_hashkey': ['id'],
        'dept_acct_officer_hashkey': ['t_ac_middleman']
    }
) }}

