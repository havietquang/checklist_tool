-- depends_on: {{ ref('v_stg_bpm_danh_muc') }}

{{ config(
    alias = 'ref_bpm_danh_muc',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['bpm', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['id', 'loai', 'ma', 'ten', 'ghi_chu', 'stt', 'trang_thai', 'nguoi_tao', 'ngay_tao', 'nguoi_update', 'ngay_update'] -%}

{{ ref_table(
    src_table='danh_muc',
    src_type='bpm_danh_muc',
    src_code="concat_ws('-', cast(id as string), nvl(cast(loai as string),''))",
    src_des="ma || '-' || ten",
    source_name='bpm'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
