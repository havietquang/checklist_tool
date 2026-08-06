-- depends_on: {{ ref('v_stg_t24_t24_category') }}

{{ config(
    alias = 'ref_t24_category',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_short_name', 't_product', 't_prod_id', 't_co_vat', 't_type_business', 't_is_mand'] -%}

{{ ref_table(
    src_table='t24_category',
    src_type='category',
    src_code="id",
    src_des="t_description",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
