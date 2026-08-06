{{ config(
    alias = 'link_ldm_partner_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_ldm_partner_customer_hashkey'],
    skip_matched_step = true,
    tags = ['qldt', 'zonec', 'all']
) }}

{% set source_name = 'qldt' %}
{% set source_table = 'ldm_partner' %}
{% set source_model = 'v_stg_qldt_ldm_partner' %}
{% set raw_sql = None %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = 'link_ldm_partner_customer_hashkey',
    source_business_key_cols = ['partner_id', 'cif'],
    foreign_business_key_cols = {
        'ldm_partner_hashkey': ['partner_id'],
        'customer_hashkey': ['cif'],
    }
) }}
