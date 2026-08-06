{{ config(
    alias = 'link_users_logon_branch',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_users_logon_branch_hashkey'],
    skip_matched_step = true,
    tags = ['newfo', 'zonec', 'all']
) }}

{% set source_name = 'newfo' %}
{% set source_table = 'users_logon' %}
{% set source_model = 'v_stg_newfo_users_logon' %}
{% set raw_sql = None %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = 'link_users_logon_branch_hashkey',
    source_business_key_cols = ['user_id', 'branch_code'],
    foreign_business_key_cols = {
        'users_logon_hashkey': ['user_id'],
        'branch_hashkey': ['branch_code'],
    }
) }}
