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
    alias = 'sat_xl_ksgn_chung_can_bo_danh_gia',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['xl_ksgn_chung_hashkey', 'hashdiff', 'source_event_date'],
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
{% set source_table = 'xl_ksgn_chung' %}
{% set hashdiff_col = 'hashdiff_xl_ksgn_chung_can_bo_danh_gia' %}
{% set hub_hashkey = 'xl_ksgn_chung_hashkey' %}
{% set source_model = 'v_stg_bpm_xl_ksgn_chung' %}
{% set list_cols = [
    'thoi_gian_nhan_task_moi_nhat', 'cbdvtd_tgian_nhan_task', 'cbtntttm_tgian_nhan_task', 'cbgdtd_tgian_nhan_task', 'cbtntttm_id', 'ket_qua_phe_duyet', 'nhom_cbxl_tntttm', 'st_cap_pd_id', 'cb_phap_che_id', 'nhom_cbxl_dvtd', 'diem_tntttm', 'diem_gdtd', 'diem_dvtd', 'nhom_khach_hang', 'xu_ly_hs', 'co_giam_tat', 'cbql_hdtd', 'dong_hdtd_cu', 'dieu_chinh_hdtd', 'can_bo_theo_gioi'
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

