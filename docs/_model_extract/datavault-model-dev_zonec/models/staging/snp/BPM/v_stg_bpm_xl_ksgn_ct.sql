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
    alias = 'v_stg_bpm_xl_ksgn_ct',
    materialized = 'view',
    tags = ['bpm', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('bpm'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('xl_ksgn_ct'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['gd_chinh_id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : None = nguon khong co cot ngay su kien ro rang;
                            macro se dung ngay load thay the.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung, mo ta chi tiet nghiep vu va gia tri
                            giao dich trong luong KSGN.
========================================================================
*/

{% set source_name = "bpm" -%}
{% set source_table = "xl_ksgn_ct" -%}
{% set business_key_cols = ['gd_chinh_id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_xl_ksgn_ct': ['gd_chitiet_id', 'giaodich_loai', 'ngay_tao', 'nguoi_tao', 'nhom_nghiepvu', 'nghiepvu_ct', 'so_tien_gd', 'ghi_chu', 'so_luong', 'gtri_giaodich', 'gtri_giaodich_dong']
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
    CAST(src.gd_chitiet_id AS STRING) AS ma_key,

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
{% if source_event_date_col is not none %}
where {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
{% endif %}
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY gd_chinh_id, gd_chitiet_id
    ORDER BY etl_time DESC
) = 1
{%- endset %}

{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=hashdiff_satellite_dict,
    source_event_date_col=source_event_date_col,
    source_event_date_dttype=source_event_date_dttype,
    source_name=source_name,
    raw_sql=raw_sql
) }}
{% endif -%}
