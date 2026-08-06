{{ config(
    alias = 'hub_app_product',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['app_product_hashkey'],
    skip_matched_step = true,
    tags = ['comb', 'zonec', 'all']
) }}

{% set source_name = 'comb' %}
{% set unique_key = 'app_product_hashkey' %}
{% set business_key = 'productcode' %}
{% set source_table = 'app_product' %}
{% set source_model = 'v_stg_comb_app_product' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}
