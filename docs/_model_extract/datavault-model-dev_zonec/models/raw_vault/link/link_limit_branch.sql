{{ config(
    alias = 'link_limit_branch',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_limit_branch_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'limit', 'phase1', 'all']
) }}

{% set source_model = 'v_stg_t24_t24_limit' %}
{% set source_name = 't24' %}
{% set source_table = 't24_limit' %}
{% set unique_key = 'link_limit_branch_hashkey' %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = ['id', 't_company_id'],
    foreign_business_key_cols = {
        'limit_hashkey': ['id'],
        'branch_hashkey': ['t_company_id']
    }
) }}

