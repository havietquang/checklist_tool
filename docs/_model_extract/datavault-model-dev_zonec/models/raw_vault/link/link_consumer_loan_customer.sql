{{ config(
    alias = 'link_consumer_loan_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_consumer_loan_customer_hashkey'],
    skip_matched_step = true,
    tags = ['comb', 'zonec', 'all', 'bv_zonec']
) }}

{% set source_name = 'comb' %}
{% set source_table = 'consumer_loan' %}
{% set source_model = 'v_stg_comb_consumer_loan' %}
{% set raw_sql = None %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = 'link_consumer_loan_customer_hashkey',
    source_business_key_cols = ['contract_no', 'customer_id'],
    foreign_business_key_cols = {
        'consumer_loan_hashkey': ['contract_no'],
        'customer_hashkey': ['customer_id'],
    }
) }}
