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
    alias = 'sat_qlns_nguoi_lao_dong_info_don_vi',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['qlns_nguoi_lao_dong_info_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
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
{% set source_table = 'qlns_nguoi_lao_dong_info' %}
{% set hashdiff_col = 'hashdiff_qlns_nguoi_lao_dong_info_don_vi' %}
{% set hub_hashkey = 'qlns_nguoi_lao_dong_info_hashkey' %}
{% set source_model = 'v_stg_bpm_qlns_nguoi_lao_dong_info' %}
{% set list_cols = [
    'khoi',
    'ma_khoi',
    'don_vi',
    'ma_don_vi',
    'phong_ban',
    'ma_phong_ban',
    'bo_phan',
    'ma_bo_phan',
    'to_nhom',
    'ma_to_nhom',
    'noi_lam_viec',
    'chuc_danh',
    'ma_chuc_danh',
    'chuc_danh_nnv',
    'ma_chuc_danh_nnv',
    'chuc_danh_1',
    'phan_nhom_chuc_danh',
    'cap_bac',
    'ma_cap_bac',
    'tham_nien_vi_tri',
    'ten_dang_nhap'
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

