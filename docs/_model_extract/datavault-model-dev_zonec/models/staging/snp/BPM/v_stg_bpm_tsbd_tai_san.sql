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
    alias = 'v_stg_bpm_tsbd_tai_san',
    materialized = 'view',
    tags = ['bpm', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('bpm'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('tsbd_tai_san'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['ma_tai_san']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('DATADATE'),
                            dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name = "bpm" -%}
{% set source_table = "tsbd_tai_san" -%}
{% set business_key_cols = ['ma_tai_san'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict =
{
   "hashdiff_tsbd_tai_san_thong_tin_chung" : ['loai_tai_san', 'ten_tai_san', 'tinh_tp_id', 'quan_huyen_id', 'mo_ta', 'dia_chi', 'trang_thai', 'ngay_tao', 'nhom_tai_san_id', 'loai_tai_san_id', 'ctiet_tai_san_id', 'nguon_tao', 'nguoi_cap_nhat', 'ngay_cap_nhat', 'phuong_xa_id', 'nguoi_tao', 'nguoi_xu_ly', 'ngay_chuyen_xu_ly', 'tai_san_goc', 'ma_ts_t24', 'dvkd_tao'],
   "hashdiff_tsbd_tai_san_phuong_tien": ['ptvt_loaiphuongtien_id', 'ptvt_hangxs', 'ptvt_bienks', 'ptvt_congnang', 'ptvt_tentau', 'ptvt_sodky', 'ptvt_taitrong', 'dong_xe'],
   "hashdiff_tsbd_tai_san_thong_tin_khac" : ['tai_san_id','vongop_mack', 'vongop_tochucnhan', 'hanghoa_tenquycach', 'tskhac_tt_taisan', 'tskhac_ghichu', 'bds_can_cu_dg', 'bds_ma_can_ho', 'bds_ngay_cap_cn', 'so_giay_cn', 'giayto_to_chuc', 'giayto_menh_gia', 'giayto_ky_han', 'quyenphatsinh_ten', 'quyenphatsinh_sohopdong']
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
{% if source_event_date_col is not none %}
where {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
{% endif %}
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY MA_TAI_SAN
    ORDER BY DATADATE DESC, etl_time DESC
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
