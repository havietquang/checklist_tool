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
    alias = 'v_stg_bpm_khach_hang_doanh_nghiep',
    materialized = 'view',
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = "bpm" -%}
{% set source_table = "khach_hang_doanh_nghiep" -%}
{% set business_key_cols = ['khach_hang_id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_khach_hang_doanh_nghiep': ['id','ma_dang_ky_kinh_doanh','ngay_cap','noi_cap','thoi_han_hoat_dong','giay_phep_nganh_nghe','ma_giay_phep_nganh_nghe','noi_cap_giay_phep_nganh_nghe','ngay_cap_giay_phep_nganh_nghe','hluc_giay_phep_nganh_nghe','ngay_hoat_dong','nganh_dang_ky_chinh','von_dieu_le','nguoi_dai_dien_phap_luat','chuc_vu_nguoi_dd','so_nhan_vien_van_phong','so_nhan_vien_cong_xuong','ngay_tao','trang_thai','doanh_thu_nam_gan_nhat','tong_tai_san_nam_gan_nhat','tong_du_no_tctd','phan_khuc_khach_hang_id','ngay_thanh_lap','dia_chi_dkkd','nganh_nghe_dky_id','giay_chung_nhan_dau_tu','doanh_thu_nhom_kh_lien_quan','han_muc_rrtd_cua_kh','dn_co_phat_trien_da_dac_thu']
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
