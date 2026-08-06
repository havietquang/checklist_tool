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
    alias = 'v_stg_bpm_lich_su_giao_dich',
    materialized = 'view',
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = "bpm" -%}
{% set source_table = "lich_su_giao_dich" -%}
{% set business_key_cols = ['gd_id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_lich_su_giao_dich': ['vai_tro_nguoi_xl','vai_tro_tiep_theo','vai_tro_truoc','thoi_diem_bat_dau','thoi_diem_ket_thuc','ten_tac_vu','trang_thai_ban_dau','trang_thai_ket_thuc','luong_id','ket_qua_xu_ly','task_id','nguoi_tao_id','ngay_tao','ngay_cap_nhat','chuc_danh','thoi_gian_xu_ly','don_vi_id']
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
    CAST(src.ls_id AS STRING) AS ma_key,
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
    PARTITION BY ls_id
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
