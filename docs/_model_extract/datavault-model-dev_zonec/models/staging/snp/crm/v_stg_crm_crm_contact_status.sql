{{ config(
    alias = 'v_stg_crm_crm_contact_status',
    materialized = 'view',
    tags = ['crm', 'reference', 'phase2', 'all']
) }}

{% set source_name = "crm" -%}
{% set source_table = "crm_contact_status" -%}
{% set business_key_cols = ['contact_status_id'] -%}
{% set list_cols = ['contact_status_id', 'contact_status_name', 'status', 'position', 'kh_denhan_bh', 'kh_cosp_dexuat', 'kh_roibo', 'hd_tiengui_denhan', 'sn_khachhang', 'kh_hienhuu', 'taikichhoat', 'kh_expiredcard', 'chbh_ganden', 'cust_group'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict = none -%}

{% if execute -%}
{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=hashdiff_satellite_dict,
    source_event_date_col=source_event_date_col,
    source_name=source_name
        ,list_cols=list_cols
        ) }}
{% endif -%}
