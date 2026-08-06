/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['bpm', 'phase2'] = filter khi run (dbt run --select tag:bpm)
====================================================================
*/
{{ config(
    alias = 'v_stg_bpm_tdcn_sp_nhu_cau_td',
    materialized = 'view',
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = "bpm" -%}
{% set source_table = "tdcn_sp_nhu_cau_td" -%}
{% set business_key_cols = ['gd_id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_giao_dich_tdcn_sp_nhu_cau_td': ['san_pham_id','loai_san_pham','phan_nhom_kh_theo_sp','phuong_thuc_cho_vay','ty_le_vay','tong_nhu_cau_von','so_tien_vay_dx','thoi_gian_vay','lai_suat_vay_du_kien','du_no_hien_tai_sp','rrtd_co_tsbd','rrtd_khong_co_tsbd','rrtd_tat_ca_sp','rrtd_tat_ca_sp_khong_tsbd','rrtd_sp_thong_thuong','rrtd_sp_thong_thuong_khong_tsbd','ngay_tao','dong_vay_co_cic','so_tien_pd','rrtd_co_tsbd_pd','rrtd_khong_co_tsbd_pd','rrtd_tat_ca_sp_pd','rrtd_tat_ca_sp_khong_tsbd_pd','rrtd_sp_thong_thuong_pd','rrtd_sp_thong_thuong_khong_tsbd_pd','tong_rrtd_st','tong_rrtd_xl','dieu_kien_bu_dap','nguoi_so_ts_tu_von_vay','rrtd_doi_voi_kh_ocb','muc_dich_vay','rrtd_doi_voi_kh_ocb_pd','rrtd_trinhcaptd_lan_nay','rrtd_trinhcaptd_lan_nay_pd','thoi_gian_an_han','mua_ban_uy_quyen','rrtd_tat_ca_sp_khong_tsbd_temp','khu_vuc_khach_hang','phuong_phap_cm_thu_nhap','khoan_vay_theo_cs_cbnv','muc_dich','phuong_phap_cmtn','khoan_vay_cs_cbnv']
}
-%}

{% if execute -%}
{%- set columns = get_columns(source(source_name, source_table)) -%}
{%- set cols_name = [] -%}
{%- for column in columns -%}{%- do cols_name.append(column.name) -%}{%- endfor -%}

{%- set raw_sql %}
select
    {{ hash_column(business_key_cols, source_name) }} as hashkey,
    {% for column in columns %}src.{{ column.name }},
    {% endfor %}
    CAST(src.id AS STRING) AS ma_key,
    {{ hash_column(cols_name, source_name) }} as hashdiff_full,
    {% for k, v in hashdiff_satellite_dict.items() %}{{ hash_column(v, source_name) }} as {{ k }},
    {% endfor %}
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    '{{ source_name }}' as record_source,
    cast(current_timestamp as timestamp) as load_timestamp
from {{ source(source_name, source_table) }} src
{% if source_event_date_col is not none %}
where {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
{% endif %}
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY id
    ORDER BY etl_time DESC
) = 1
{%- endset %}

{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=hashdiff_satellite_dict,
    source_event_date_col=source_event_date_col,
    source_name=source_name,
    raw_sql=raw_sql
) }}

{% endif -%}
