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
tags                : ['omni'] = filter khi run (dbt run --select tag:omni)
====================================================================
*/

{{ config(
    alias = 'sat_payment_order_classification',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['payment_order_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['omni', 'payment_order', 'phase1', 'all']
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

{% set source_name = 'omni' %}
{% set source_table = 'payment_order' %}
{% set hashdiff_col = 'hashdiff_payment_order_classification' %}
{% set hub_hashkey = 'payment_order_hashkey' %}
{% set source_model = 'v_stg_omni_payment_order' %}
{% set list_cols = ['status as status', 'bank_status as bank_status', 'pmt_mode as pmt_mode', 'pmt_type as pmt_type', 'priority as priority', 'role as role', 'entry_class as entry_class', 'intra_legal_entity as intra_legal_entity', 'remaining_occurrences as remaining_occurrences', 'account_scheme as account_scheme'] %}
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

