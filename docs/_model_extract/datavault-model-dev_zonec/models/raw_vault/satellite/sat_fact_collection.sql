{{ config(
    alias = 'sat_fact_collection',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['consumer_loan_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['comb', 'zonec', 'all']
) }}

{% set source_name = 'comb' %}
{% set source_table = 'fact_collection_comb' %}
{% set hashdiff_col = 'hashdiff_fact_collection' %}
{% set hub_hashkey = 'consumer_loan_hashkey' %}
{% set source_model = 'v_stg_comb_fact_collection_comb' %}
{% set list_cols = [
    'bucket_allocation',
    'app_id',
    'customer_id',
    'branch_code',
    'currency',
    'principal',
    'interest',
    'penalty',
    'date_cob',
    'created_date'
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
