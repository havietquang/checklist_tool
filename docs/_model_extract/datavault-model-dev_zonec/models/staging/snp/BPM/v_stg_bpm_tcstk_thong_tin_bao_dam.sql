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
    alias = 'v_stg_bpm_tcstk_thong_tin_bao_dam',
    materialized = 'view',
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = "bpm" -%}
{% set source_table = "tcstk_thong_tin_bao_dam" -%}
{% set business_key_cols = ['gd_id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_giao_dich_tcstk_thong_tin_bao_dam': ['ten_tsbd','ma_tsbd','gia_tri_tsbd','tyle_bao_dam','trang_thai_ts','ngay_bat_dau_co_hl','ngay_het_han','han_muc_tc_bd','hm_tc_con_lai','hm_dc_da_sd','ngay_tao','nguoi_tao','ngay_cap_nhat','nguoi_cap_nhat','is_delete','id_ttgd','giatri_baodam','ngay_ms','ngay_dao_han','ma_hm','ma_lkq','trang_thai_phong_toa','status','loai_tien','lai_suat','so_so_tk','ki_han','ten_san_pham','productcode','lai_suat_tk','stt_so','trang_thaihm','ly_do','hinh_thuc_tt_stk','ma_phong_toa','so_tai_khoan_so','madcaz','is_checkstk','is_tao_ts_bd','is_dieu_chinh','is_phong_toa','ma_chi_nhanh_stk','is_giai_toa_ts','ma_giaitoa','is_giai_chap_ts','ma_giaichap','is_tat_toan','ma_tat_toan']
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
