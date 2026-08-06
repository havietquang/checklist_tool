{{ config(
    alias = 'sat_app_product',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['app_product_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['comb', 'zonec', 'all']
) }}

{% set source_name = 'comb' %}
{% set source_table = 'app_product' %}
{% set hashdiff_col = 'hashdiff_app_product' %}
{% set hub_hashkey = 'app_product_hashkey' %}
{% set source_model = 'v_stg_comb_app_product' %}
{% set list_cols = [
    'producttype',
    'productname',
    'status',
    'minloanamount',
    'maxloanamount',
    'interestrate',
    'mintenor',
    'maxtenor',
    'validfrom',
    'validto',
    'changeddate'
] %}
{% set raw_sql = None %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
