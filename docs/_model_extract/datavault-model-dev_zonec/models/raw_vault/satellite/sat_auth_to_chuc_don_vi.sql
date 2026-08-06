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
    alias = 'sat_auth_to_chuc_don_vi',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['auth_to_chuc_don_vi_hashkey', 'hashdiff', 'source_event_date'],
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
{% set source_table = 'auth_to_chuc_don_vi' %}
{% set hashdiff_col = 'hashdiff_auth_to_chuc_don_vi' %}
{% set hub_hashkey = 'auth_to_chuc_don_vi_hashkey' %}
{% set source_model = 'v_stg_bpm_auth_to_chuc_don_vi' %}
{% set list_cols = [
    'ma_don_vi',
    'don_vi_cap_tren',
    'ten_don_vi',
    'cap_do',
    'loai_don_vi',
    'ocb_hrm_id',
    'trang_thai',
    'ghi_chu',
    'tinh_tp_id',
    'phan_cap_don_vi',
    'thamvan_capky',
    'ishr',
    'cic',
    'phan_khuc_khai_thac',
    'don_vi_trien_khai_dvtd',
    'custgroup',
    'parent_id_kt'
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

