-- depends_on: {{ ref('v_stg_bpm_sk10_san_pham') }}

{{ config(
    alias = 'ref_bpm_sk10_san_pham',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['bpm', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['id', 'ma_san_pham', 'ten_san_pham', 'phan_nhom_san_pham', 'parent_group', 'hieu_luc_sp', 'ghi_chu', 'category_t24', 'loan_support_t24', 'dieu_kien_t24', 'ngay_tao'] -%}

{{ ref_table(
    src_table='sk10_san_pham',
    src_type='bpm_sk10_san_pham',
    src_code="concat_ws('', cast(id as string), cast(ma_san_pham as string))",
    src_des="ma_san_pham",
    source_name='bpm'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
