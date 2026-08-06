-- depends_on: {{ ref('v_stg_bpm_c_danh_muc') }}

{{ config(
    alias = 'ref_bpm_c_danh_muc',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['bpm', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['ten_danh_muc', 'ghi_chu', 'parent_id', 'trang_thai'] -%}

{{ ref_table(
    src_table='c_danh_muc',
    src_type='bpm_c_danh_muc',
    src_code="id",
    src_des="loai_danh_muc",
    source_name='bpm'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
