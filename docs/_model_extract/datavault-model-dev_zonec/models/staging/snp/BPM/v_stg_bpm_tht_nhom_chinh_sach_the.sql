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
    alias = 'v_stg_bpm_tht_nhom_chinh_sach_the',
    materialized = 'view',
    tags = ['bpm', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('bpm'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('tht_nhom_chinh_sach_the'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['gd_id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('DATADATE'),
                            dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung, phan anh nhom chinh sach the
                            va thong tin chi tiet the chinh/the phu.
========================================================================
*/

{% set source_name = "bpm" -%}
{% set source_table = "tht_nhom_chinh_sach_the" -%}
{% set business_key_cols = ['gd_id'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_giao_dich_tht_nhom_chinh_sach_the': ['nhom_chinh_sach_ten', 'ngay_tao', 'size_chi_tiet_1', 'is_the_phu', 'ma_nhom_chinh_sach', 'giay_to_the_phu', 'ma_chi_tiet_1', 'chi_tiet_1_ten', 'ma_chi_tiet_2', 'chi_tiet_2_ten', 'san_pham_the', 'id_the_chinh']
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

    --EXTRA COLUMNS
    CAST(src.id AS STRING) AS ma_key,

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
