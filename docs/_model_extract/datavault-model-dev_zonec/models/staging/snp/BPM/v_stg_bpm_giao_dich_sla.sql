/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['bpm'] = filter khi run (dbt run --select tag:bpm)
====================================================================
*/
{{ config(
    alias = 'v_stg_bpm_giao_dich_sla',
    materialized = 'view',
    tags = ['bpm', 'phase1', 'zonec', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('bpm'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('giao_dich_tsbd'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['GD_ID']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('NGAY_TAO'),
                            dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/
{% set source_name = "bpm" -%}
{% set source_table = "giao_dich_sla" -%}
{% set business_key_cols = ['gd_id'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_giaodich_sla': ['quy_trinh', 'sla', 'thoi_gian_xl_vitri_1', 'thoi_gian_xl_vitri_2', 'thoi_diem_nhan_vitri_1', 'thoi_diem_nhan_vitri_2', 'thoi_diem_nhan_vitri_1_cuoi', 'thoi_diem_nhan_vitri_2_cuoi', 'thoi_gian_xl_vitri_3', 'thoi_gian_xl_vitri_4', 'thoi_diem_nhan_vitri_3', 'thoi_diem_nhan_vitri_4', 'thoi_diem_nhan_vitri_3_cuoi', 'thoi_diem_nhan_vitri_4_cuoi', 'thoi_gian_den_han', 'sla_vitri_2', 'sla_vitri_3', 'sla_vitri_4', 'sla_vitri_5', 'thoi_gian_xl_vitri_5', 'thoi_diem_nhan_vitri_5', 'thoi_diem_nhan_vitri_5_cuoi', 'trang_thai', 'thoi_gian_xl_vitri_6', 'thoi_diem_nhan_vitri_6', 'thoi_diem_nhan_vitri_6_cuoi', 'thoi_gian_xl_vitri_7', 'thoi_diem_nhan_vitri_7', 'thoi_diem_nhan_vitri_7_cuoi', 'sla_vitri_8', 'thoi_gian_xl_vitri_8', 'thoi_diem_nhan_vitri_8', 'thoi_diem_nhan_vitri_8_cuoi', 'sla_vitri_9', 'thoi_gian_xl_vitri_9', 'thoi_diem_nhan_vitri_9', 'thoi_diem_nhan_vitri_9_cuoi', 'sla_vitri_12', 'thoi_gian_xl_vitri_12', 'thoi_diem_nhan_vitri_12', 'thoi_diem_nhan_vitri_12_cuoi', 'sla_vitri_14', 'thoi_gian_xl_vitri_14', 'thoi_diem_nhan_vitri_14', 'thoi_diem_nhan_vitri_14_cuoi'],
    'hashdiff_xl_ksgn_chung_sla': ['quy_trinh', 'sla', 'thoi_gian_xl_vitri_1', 'thoi_gian_xl_vitri_2', 'thoi_diem_nhan_vitri_1', 'thoi_diem_nhan_vitri_1_cuoi', 'thoi_diem_nhan_vitri_2_cuoi', 'thoi_gian_xl_vitri_3', 'thoi_gian_xl_vitri_4', 'thoi_diem_nhan_vitri_3', 'thoi_diem_nhan_vitri_4', 'thoi_diem_nhan_vitri_3_cuoi', 'thoi_diem_nhan_vitri_4_cuoi', 'thoi_gian_den_han', 'sla_vitri_2', 'sla_vitri_3', 'sla_vitri_5', 'thoi_gian_xl_vitri_5', 'thoi_diem_nhan_vitri_5', 'thoi_diem_nhan_vitri_5_cuoi', 'trang_thai', 'thoi_gian_xl_vitri_6', 'thoi_diem_nhan_vitri_6', 'thoi_diem_nhan_vitri_6_cuoi', 'thoi_gian_xl_vitri_7', 'thoi_diem_nhan_vitri_7', 'thoi_diem_nhan_vitri_7_cuoi', 'sla_vitri_4', 'sla_vitri_8', 'thoi_gian_xl_vitri_8', 'thoi_diem_nhan_vitri_8', 'thoi_diem_nhan_vitri_8_cuoi', 'sla_vitri_9', 'thoi_gian_xl_vitri_9', 'thoi_diem_nhan_vitri_9', 'thoi_diem_nhan_vitri_9_cuoi', 'sla_vitri_12', 'thoi_gian_xl_vitri_12', 'thoi_diem_nhan_vitri_12', 'thoi_diem_nhan_vitri_12_cuoi', 'sla_vitri_14', 'thoi_gian_xl_vitri_14', 'thoi_diem_nhan_vitri_14', 'thoi_diem_nhan_vitri_14_cuoi'],
    'hashdiff_pdtd_nhom_giao_dich_sla': ['quy_trinh', 'sla', 'thoi_gian_xl_vitri_1', 'thoi_gian_xl_vitri_2', 'thoi_diem_nhan_vitri_1', 'thoi_diem_nhan_vitri_2', 'thoi_diem_nhan_vitri_1_cuoi', 'thoi_diem_nhan_vitri_2_cuoi', 'thoi_gian_xl_vitri_3', 'thoi_gian_xl_vitri_4', 'thoi_diem_nhan_vitri_3', 'thoi_diem_nhan_vitri_4', 'thoi_diem_nhan_vitri_3_cuoi', 'thoi_diem_nhan_vitri_4_cuoi', 'thoi_gian_den_han', 'sla_vitri_2', 'sla_vitri_3', 'sla_vitri_5', 'thoi_gian_xl_vitri_5', 'thoi_diem_nhan_vitri_5', 'thoi_diem_nhan_vitri_5_cuoi', 'trang_thai', 'thoi_gian_xl_vitri_6', 'thoi_diem_nhan_vitri_6', 'thoi_diem_nhan_vitri_6_cuoi', 'thoi_gian_xl_vitri_7', 'thoi_diem_nhan_vitri_7', 'thoi_diem_nhan_vitri_7_cuoi', 'sla_vitri_4', 'sla_vitri_8', 'thoi_gian_xl_vitri_8', 'thoi_diem_nhan_vitri_8', 'thoi_diem_nhan_vitri_8_cuoi', 'sla_vitri_9', 'thoi_gian_xl_vitri_9', 'thoi_diem_nhan_vitri_9', 'thoi_diem_nhan_vitri_9_cuoi', 'sla_vitri_12', 'thoi_gian_xl_vitri_12', 'thoi_diem_nhan_vitri_12', 'thoi_diem_nhan_vitri_12_cuoi', 'sla_vitri_14', 'thoi_gian_xl_vitri_14', 'thoi_diem_nhan_vitri_14', 'thoi_diem_nhan_vitri_14_cuoi']
}
-%}

/*
------------------------------------------------------------------------
STAGE MACRO CALL
------------------------------------------------------------------------
Guard `if execute` ngan macro chay luc dbt parse/compile
(tranh loi khi chua co context thuc thi).
Macro `stage()` se sinh ra cau SELECT day du gom:
  - Tat ca cot goc tu source
  - Cot hashkey (hash cua business_key_cols)
  - Cac cot hashdiff theo hashdiff_satellite_dict
  - Cot record_source, source_event_date, load_timestamp
------------------------------------------------------------------------
*/
{% if execute -%}
{%- set columns = get_columns(source(source_name, source_table)) -%}
{%- set cols_name = [] -%}
{%- for column in columns -%}{%- do cols_name.append(column.name) -%}{%- endfor -%}

{%- set raw_sql %}
select
    --HASH KEY
    {{ hash_column(business_key_cols, source_name) }} as hashkey,

    --ALL COLUMNS FROM SOURCE TABLE
    {% for column in columns %}src.{{ column.name }},
    {% endfor %}

    --HASHDIFF FULL
    {{ hash_column(cols_name, source_name) }} as hashdiff_full,

    --HASHDIFF SATELLITES
    {% for k, v in hashdiff_satellite_dict.items() %}{{ hash_column(v, source_name) }} as {{ k }},
    {% endfor %}

    --TIME & SOURCE COLUMNS
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    '{{ source_name }}' as record_source,
    cast(current_timestamp as timestamp) as load_timestamp

from {{ source(source_name, source_table) }} src
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
