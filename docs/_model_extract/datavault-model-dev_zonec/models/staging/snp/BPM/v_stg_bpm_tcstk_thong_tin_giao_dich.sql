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
    alias = 'v_stg_bpm_tcstk_thong_tin_giao_dich',
    materialized = 'view',
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = "bpm" -%}
{% set source_table = "tcstk_thong_tin_giao_dich" -%}
{% set business_key_cols = ['gd_id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_giao_dich_tcstk_thong_tin_giao_dich': ['id','ma_gd_omni','nguoi_tao_gd_omni','ngay_tao_gd_omni','so_tien_de_nghi','loai_tien_dn','so_tien_de_xuat','loai_tien_dx','so_tien_hm_pd','loai_tien_pd','trang_thai_gd','khach_hang_id','tt_tai_khoan_tc','tong_so_tien_vay','ngay_bd_hm','han_muc_tc_bd','hm_tc_con_lai','hm_dc_da_sd','ngay_tat_toan','lai_suat_khi_tat_toan','so_tien_khi_tat_toan','ma_don_vi_kd_ql','ma_don_vi_khoi_tao','don_vi_kt','ngay_kt_hm','nguoi_pd','ngay_pd','loai_gd','laisuat','ngay_tao','nguoi_tao','ngay_cap_nhat','nguoi_cap_nhat','is_delete','trang_thai_gd_omni','loai_gd_id']
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
    PARTITION BY gd_id
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
