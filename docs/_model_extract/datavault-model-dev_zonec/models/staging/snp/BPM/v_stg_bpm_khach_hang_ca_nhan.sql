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
    alias = 'v_stg_bpm_khach_hang_ca_nhan',
    materialized = 'view',
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = "bpm" -%}
{% set source_table = "khach_hang_ca_nhan" -%}
{% set business_key_cols = ['khach_hang_id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_khach_hang_ca_nhan': ['id','ngay_sinh','cmnd','noi_cap_cmnd','ngay_cap_cmnd','ho_khau_thuong_tru','noi_o_hien_tai','so_dien_thoai','email','ngay_tao','trang_thai','tinh_trang_hnhan_id','tinh_trang_hnhan','ho_chieu','can_cuoc_cong_dan','gioi_tinh','visa','ngay_cap_visa','ngay_het_han_visa','ngay_hieu_luc_visa','noi_cap_visa','thoi_han_cu_tru_vn','ngay_het_han_cmnd','thu_nhap_hang_thang','tham_nien_lam_viec','the_can_cuoc','quoc_tich']
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
