-- depends_on: {{ ref('v_stg_crm_crm_contact_type') }}

{{ config(
    alias = 'ref_crm_contact_type',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['crm', 'reference','phase2', 'all']
) }}

{% set list_cols = ['status', 'position', 'kh_denhan_bh', 'kh_cosp_dexuat', 'kh_roibo', 'hd_tiengui_denhan', 'sn_khachhang', 'kh_hienhuu', 'taikichhoat', 'kh_expiredcard', 'chbh_ganden', 'cust_group', 'iscall'] -%}

{{ ref_table(
    src_table='crm_contact_type',
    src_type='crm_contact_type',
    src_code="contact_type_id",
    src_des="contact_type_name",
    source_name='crm'
    ,list_cols=list_cols
    ,hashdiff_name='hashdiff_full'
) }}
