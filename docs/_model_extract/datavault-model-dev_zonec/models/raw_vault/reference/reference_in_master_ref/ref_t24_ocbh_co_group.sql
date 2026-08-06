-- depends_on: {{ ref('v_stg_t24_t24_ocbh_co_group') }}

{{ config(
    alias = 'ref_t24_ocbh_co_group',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff_full'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'zonec']
) }}

{% set list_cols = ['MVALUE'] -%}

{{ ref_table(
    src_table='t24_ocbh_co_group',
    src_type='co_group',
    src_code="id",
    src_des="description",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
