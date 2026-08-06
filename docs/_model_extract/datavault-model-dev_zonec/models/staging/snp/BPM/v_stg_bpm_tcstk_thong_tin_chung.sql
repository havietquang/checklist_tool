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
    alias = 'v_stg_bpm_tcstk_thong_tin_chung',
    materialized = 'view',
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = "bpm" -%}
{% set source_table = "tcstk_thong_tin_chung" -%}
{% set business_key_cols = ['gd_id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_giao_dich_tcstk_thong_tin_chung': ['id','ma_gd_omni','nguoi_tao_gd_omni','ngay_tao_gd_omni','so_tien_de_nghi','loai_tien_dn','so_tien_de_xuat','loai_tien_dx','so_tien_hm_pd','loai_tien_pd','trang_thai_gd','ngay_bd_hm','ngay_kt_hm','nguoi_pd','ngay_pd','loai_gd','ngay_tao','nguoi_tao','ngay_cap_nhat','nguoi_cap_nhat','is_delete','trang_thai_gd_omni','action','tkwa','biendols','ngay_kh_dx','ma_hm','ma_lkq','ma_don_vi_khoi_tao','decesion','don_vi_khoi_tao','next_decesion','so_cif','ten_kh','trang_thai_hoat_dong','so_tk_tc','email','sodt','trang_thai','laisuat','is_tat_toan','nghiep_vu','ma_gd_mo','no_goc','no_lai','du_no_goc_api','du_no_lai_api','ngay_tat_toan','tong_du_no','loai_tien','list_tai_lieu','list_ts','is_tao_tk_tc','is_tao_lkq','is_tao_hm','is_cai_dat_hm','is_tao_wa','is_gan_hm','is_dc_hm_tc','is_go_hm_tc','is_kep_lai']
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
