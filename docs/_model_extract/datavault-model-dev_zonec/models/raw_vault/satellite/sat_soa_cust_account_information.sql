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
tags                : ['ocbchannel'] = filter khi run (dbt run --select tag:ocbchannel)
====================================================================
*/

{{ config(
    alias = 'sat_soa_cust_account_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['soa_cust_account_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['ocbchannel', 'soa_cust_account', 'zonec']
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

{% set source_name = 'ocbchannel' %}
{% set source_table = 'soa_cust_account' %}
{% set hashdiff_col = 'hashdiff_soa_cust_account_information' %}
{% set hub_hashkey = 'soa_cust_account_hashkey' %}
{% set source_model = 'v_stg_ocbchannel_soa_cust_account' %}
{% set list_cols = ['alt_account_id', 'cif', 'category', 'product_code', 'currency', 'branch_code', 'created_by', 'created_date', 'status', 'is_processing', 'processing_by', 'channel', 'last_access', 'account_no'] %}
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
