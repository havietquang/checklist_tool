{{ config(
    alias = 'link_external_transaction_giao_dich',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_external_transaction_giao_dich_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'external_transaction' %}
{% set source_model = 'v_stg_bpm_external_transaction' %}
{% set raw_sql = None %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = 'link_external_transaction_giao_dich_hashkey',
    source_business_key_cols = ['id', 'ma_giao_dich'],
    foreign_business_key_cols = {
        'external_transaction_hashkey': ['id'],
        'giao_dich_hashkey': ['ma_giao_dich'],
    }
) }}
