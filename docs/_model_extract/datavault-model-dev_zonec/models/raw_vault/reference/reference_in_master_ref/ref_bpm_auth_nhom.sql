-- depends_on: {{ ref('v_stg_bpm_auth_nhom') }}

{{ config(
    alias = 'ref_bpm_auth_nhom',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['bpm', 'reference', 'phase1', 'all']
) }}

{% set list_cols = ['id', 'ma_nhom', 'ten_nhom_viet_tat', 'ten_nhom_day_du', 'trang_thai', 'ghi_chu', 'ocb_hrm_id', 'nhom_cap_tren', 'search_scope', 'nhom_dai_dien', 'cap_phe_duyet', 'quy_trinh', 'cap_do', 'cap_do_tim_kiem', 'cap_do_ecm', 'cap_do_ecm_xlgdtd', 'cap_do_ecm_tsbd', 'json_ecm', 'ma_nhom_ten'] -%}

{{ ref_table(
    src_table='auth_nhom',
    src_type='bpm_auth_nhom',
    src_code="concat_ws('', cast(id as string), cast(ma_nhom as string))",
    src_des="ma_nhom",
    source_name='bpm'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
