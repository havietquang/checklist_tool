-- depends_on: {{ ref('v_stg_t24_t24_bc_sort_code') }}

{{ config(
    alias = 'ref_t24_bc_sort_code',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_telephone_no', 't_identity_kind'] -%}

{{ ref_table(
    src_table='t24_bc_sort_code',
    src_type='bc_sort_code',
    src_code="id",
    src_des="t_name",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
