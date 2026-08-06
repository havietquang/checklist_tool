{{ config(
    alias = 'sat_aa_arrangement_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['aa_arrangement_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'zonec', 'all']
) }}

{% set source_name = 't24' %}
{% set source_table = 't24_aa_arrangement' %}
{% set hashdiff_col = 'hashdiff_aa_arrangement_information' %}
{% set hub_hashkey = 'aa_arrangement_hashkey' %}
{% set source_model = 'v_stg_t24_t24_aa_arrangement' %}
{% set list_cols = [
    't_currency',
    't_co_code',
    't_start_date',
    't_product_line',
    't_product_group',
    't_product',
    't_linked_appl',
    't_linked_appl_id',
    't_customer_role',
    't_arr_status'
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
