/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record (thuong: hub_hashkey + hashdiff)
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['bpm'] = filter khi run (dbt run --select tag:bpm)
====================================================================
*/

{{ config(
    alias = 'sat_pdtd_nhom_giao_dich_trang_thai',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['pdtd_nhom_giao_dich_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase1', 'all']
) }}

/*
========================================================================
SATELLITE MACRO PARAMETERS
========================================================================
  - source_name         : Ten he thong nguon, dung de tao gia tri cho cot `record_source`.
  - source_table        : Ten bang nghiep vu o he thong nguon.
  - hashdiff_col        : Ten cot hashdiff da duoc tinh san o tang staging.
  - hub_hashkey         : Ten khoa hash dung de lien ket ve bang Hub/Link.
  - source_model        : Model staging lam nguon de doc du lieu.
  - list_cols           : Danh sach cac cot nghiep vu duoc luu trong Satellite.
  - raw_sql (optional)  : Cau SQL tu viet trong truong hop logic phuc tap hoac dac biet.
========================================================================
*/

{% set source_name = 'bpm' %}
{% set source_table = 'pdtd_nhom_giao_dich' %}
{% set hashdiff_col = 'hashdiff_pdtd_nhom_giao_dich_trang_thai' %}
{% set hub_hashkey = 'pdtd_nhom_giao_dich_hashkey' %}
{% set source_model = 'v_stg_bpm_pdtd_nhom_giao_dich' %}
{% set list_cols = [
    'trang_thai_giao_dich',
    'trang_thai_phe_duyet',
    'role_dang_xl',
    'trang_thai_hoat_dong',
    'ket_qua_thao_tac_cuoi',
    'process_id',
    'luong_id',
    'ngay_tao',
    'thoi_diem_thao_tac_cuoi',
    'ngay_hoan_thanh',
] %}

/* 
Truong hop khong su dung macro satellite, co the su dung raw_sql nhu ben duoi de 
viet SQL thu cong, sau do truyen vao macro satellite de tao satellite
*/
{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}

