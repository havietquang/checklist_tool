-- depends_on: {{ ref('v_stg_t24_t24_province') }}

{{ config(
    alias = 'ref_t24_province',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_nationality'] -%}

{{ ref_table(
    src_table='t24_province',
    src_type='province',
    src_code="id",
    src_des="t_province",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
