-- depends_on: {{ ref('v_stg_t24_t24_ocbh_deposit_prgm') }}

{{ config(
    alias = 'ref_t24_ocbh_deposit_prgm',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_begin_date', 't_end_date', 't_co_code'] -%}

{{ ref_table(
    src_table='t24_ocbh_deposit_prgm',
    src_type='deposit_prgm',
    src_code="id",
    src_des="t_prgm_name",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
