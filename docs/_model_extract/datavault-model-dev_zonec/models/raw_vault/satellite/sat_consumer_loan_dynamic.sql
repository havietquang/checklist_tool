{{ config(
    alias = 'sat_consumer_loan_dynamic',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['consumer_loan_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['comb', 'zonec', 'all']
) }}

{% set source_name = 'comb' %}
{% set source_table = 'consumer_loan' %}
{% set hashdiff_col = 'hashdiff_consumer_loan_dynamic' %}
{% set hub_hashkey = 'consumer_loan_hashkey' %}
{% set source_model = 'v_stg_comb_consumer_loan' %}
{% set list_cols = [
    'id'
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
