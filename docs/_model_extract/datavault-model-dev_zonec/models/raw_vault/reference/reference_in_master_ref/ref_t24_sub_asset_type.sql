-- depends_on: {{ ref('v_stg_t24_t24_sub_asset_type') }}

{{ config(
    alias = 'ref_t24_sub_asset_type',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['data_date', 't_short_descr', 't_asset_type_code'] -%}

{{ ref_table(
    src_table='t24_sub_asset_type',
    src_type='sub_asset_type',
    src_code="id",
    src_des="t_description",
    source_name='t24'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
