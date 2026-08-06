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
    alias = 'sat_omni_transaction_hist_detail',
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
{% set hashdiff_col = 'hashdiff_omni_transaction_hist_detail' %}
{% set hub_hashkey = 'omni_transaction_hist_hashkey' %}
{% set source_model = 'v_stg_esb_omni_transaction_hist' %}
{% set list_cols = ['operation_status', 'stmt_id', 'user_created', 'customer_id', 'sender', 'recipient', 'bank_code', 'bank_branch_code', 'province_code', 'clearing_network', 'qty', 'bill_sourcedata', 'mobile_phone_number', 'par_value', 'student_code', 'university_code', 'course_type', 'sourcedata', 'partner_id', 'payment_code', 'recipient_card_number', 'ewallet_phonenumber', 'payment_status', 'exchange_rate', 'amount_lcy', 'currency_lcy', 'telco_provider', 'discount_amount', 'recipient_card_account_no', 'recipient_customer_id', 'fee_type', 'debit_acct_currency', 'request_ref_id', 'fee_amount', 'virtual_account', 'virtual_account_name', 'card_no', 'card_account_no', 'phone_no', 'exchange_coin_quan', 'channel', 'batch_id'] %}
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
