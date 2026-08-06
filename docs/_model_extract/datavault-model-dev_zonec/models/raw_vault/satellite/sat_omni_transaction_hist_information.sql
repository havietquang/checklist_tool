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
tags                : ['esb'] = filter khi run (dbt run --select tag:esb)
====================================================================
*/

{{ config(
    alias = 'sat_omni_transaction_hist_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['omni_transaction_hist_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['esb', 'omni_transaction_hist', 'zonec']
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

{% set source_name = 'esb' %}
{% set source_table = 'omni_transaction_hist' %}
{% set hashdiff_col = 'hashdiff_omni_transaction_hist_information' %}
{% set hub_hashkey = 'omni_transaction_hist_hashkey' %}
{% set source_model = 'v_stg_esb_omni_transaction_hist' %}
{% set list_cols = ['ref_id', 'payment_type', 'product_type', 'created_datetime', 'execute_date', 'cif', 'debit_account_no', 'credit_account', 'amount', 'currency', 'remarks', 'eb_user_id', 'service_code', 'service_provider_code', 'bill_code', 't24_trans_no', 'source_type'] %}
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
