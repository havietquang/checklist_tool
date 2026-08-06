-- depends_on: {{ ref('v_stg_t24_t24_occupation') }}

{{ config(
    alias = 'ref_t24_occupation',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date'] -%}

{{ ref_table(
    src_table='t24_occupation',
    src_type='occupation',
    src_code="id",
    src_des="occupation_desc",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
