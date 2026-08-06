-- depends_on: {{ ref('v_stg_bpm_danh_muc_chi_tiet') }}

{{ config(
    alias = 'ref_bpm_danh_muc_chi_tiet',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['bpm', 'reference', 'zonec', 'all']
) }}

{% set list_cols = ['SUB_ID', 'PARENT_ID', 'TIEU_CHI_ID', 'GHI_CHU', 'TRANG_THAI', 'NGAY_TAO'] -%}

{{ ref_table(
    src_table='danh_muc_chi_tiet',
    src_type='bpm_danh_muc_chi_tiet',
    src_code="id",
    src_des="ten_tieu_chi",
    source_name='bpm'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
