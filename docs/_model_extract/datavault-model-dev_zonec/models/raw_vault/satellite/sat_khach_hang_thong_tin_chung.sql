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
    alias = 'sat_khach_hang_thong_tin_chung',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['khach_hang_hashkey', 'hashdiff', 'source_event_date'],
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
{% set source_table = 'khach_hang' %}
{% set hashdiff_col = 'hashdiff_khach_hang_thong_tin_chung' %}
{% set hub_hashkey = 'khach_hang_hashkey' %}
{% set source_model = 'v_stg_bpm_khach_hang' %}
{% set list_cols = [
    'loai_khach_hang',
    'ten_khach_hang',
    'ghi_chu',
    'ngay_tao',
    'xep_hang_tin_dung',
    'nhom_khach_hang_id',
    'khach_hang_no',
    'nv_cham_soc_gan_nhat',
    'dvkd_quan_ly',
    'trang_thai',
    'nhom_no_cao_nhat',
    'phan_khuc_khang',
    'hangkh',
    'isnewkh'
] %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}

