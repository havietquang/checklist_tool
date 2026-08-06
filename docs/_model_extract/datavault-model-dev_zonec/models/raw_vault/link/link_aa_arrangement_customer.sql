{{ config(
    alias = 'link_aa_arrangement_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_aa_arrangement_customer_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'zonec', 'all']
) }}

{% set source_name = 't24' %}
{% set source_table = 't24_aa_arrangement' %}
{% set source_model = 'v_stg_t24_t24_aa_arrangement' %}
{% set raw_sql = None %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = 'link_aa_arrangement_customer_hashkey',
    source_business_key_cols = ['id', 't_customer'],
    foreign_business_key_cols = {
        'aa_arrangement_hashkey': ['id'],
        'customer_hashkey': ['t_customer'],
    }
) }}
