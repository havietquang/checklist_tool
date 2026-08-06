/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record mới/thay đổi
                    : 'table' = full load
                    : 'view' = chỉ tạo view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chỉ insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khóa định danh record (thường: hub_hashkey + hashdiff)
skip_matched_step   : true = bỏ record không đổi → tăng performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['bpm'] = filter khi run (dbt run --select tag:bpm)
====================================================================
*/

{{ config(
    alias = 'sat_tsbd_tai_san_thong_tin_chung',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['tsbd_tai_san_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase1', 'all']
) }}

/*
========================================================================
SATELLITE MACRO PARAMETERS
========================================================================
  - source_name         : Tên hệ thống nguồn, dùng để tạo giá trị cho cột `record_source`.
  - source_table        : Tên bảng nghiệp vụ ở hệ thống nguồn.
  - hashdiff_col        : Tên cột hashdiff đã được tính sẵn ở tầng staging.
  - hub_hashkey         : Tên khóa hash dùng để liên kết về bảng Hub.
  - source_model        : Model staging làm nguồn để đọc dữ liệu.
  - list_cols           : Danh sách các cột nghiệp vụ được lưu trong Satellite.
  - raw_sql (optional)  : Câu SQL tự viết trong trường hợp logic phức tạp hoặc đặc biệt.
*/

{% set source_name = 'bpm' %}
{% set source_table = 'tsbd_tai_san' %}
{% set hashdiff_col = 'hashdiff_tsbd_tai_san_thong_tin_chung' %}
{% set hub_hashkey = 'tsbd_tai_san_hashkey' %}
{% set source_model = 'v_stg_bpm_tsbd_tai_san' %}
{% set list_cols = [
    'loai_tai_san',
    'ten_tai_san',
    'tinh_tp_id',
    'quan_huyen_id',
    'mo_ta',
    'dia_chi',
    'trang_thai',
    'ngay_tao',
    'nhom_tai_san_id',
    'loai_tai_san_id',
    'ctiet_tai_san_id',
    'nguon_tao',
    'nguoi_cap_nhat',
    'ngay_cap_nhat',
    'phuong_xa_id',
    'nguoi_tao',
    'nguoi_xu_ly',
    'ngay_chuyen_xu_ly',
    'tai_san_goc',
    'ma_ts_t24',
    'dvkd_tao'
] %}
{% set raw_sql = None %}

/* 
Truong hop khong su dung marco satellite, co the su dung raw_sql nhu ben duoi de 
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

