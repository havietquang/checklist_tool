{{ config(
    alias = 'link_passbook_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_passbook_customer_hashkey'],
    skip_matched_step = true,
    tags = ['newfo', 'zonec', 'all']
) }}

{% set source_name = 'newfo' %}
{% set source_table = 'passbook' %}
{% set source_model = 'v_stg_newfo_passbook' %}
{% set raw_sql = None %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = 'link_passbook_customer_hashkey',
    source_business_key_cols = ['id', 'cif'],
    foreign_business_key_cols = {
        'passbook_hashkey': ['id'],
        'customer_hashkey': ['cif'],
    }
) }}
