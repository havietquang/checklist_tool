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
    alias = 'sat_batch_trans_details',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['batch_trans_details_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['esb', 'batch_trans_details', 'zonec']
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
{% set source_table = 'batch_trans_details' %}
{% set hashdiff_col = 'hashdiff_batch_trans_details' %}
{% set hub_hashkey = 'batch_trans_details_hashkey' %}
{% set source_model = 'v_stg_esb_batch_trans_details' %}
{% set list_cols = ['batch_item_id', 'debit_account', 'credit_account', 'amount_input', 'amount', 'currency', 'cif', 'trans_status', 'transaction_fee', 'recipient_account', 'recipient', 'descriptions', 'bank_code', 'bank_branch_code', 'province_code', 'err_no', 'err_desc', 'batch_item_no', 'validation_code', 'validation_string', 'validation_status', 'recipient_bank_name', 'priority', 'item_type', 't24_trans_no', 'cref_no', 'batch_item_unique_no', 'payment_type', 'created_date', 'updated_date', 'partner_recipient_name', 'partner_validation_status', 'prev_partner_validation_status', 'partner_validation_string', 'partner_query_error_code', 'partner_query_error_msg', 'partner_payment_status', 'partner_payment_error_code', 'partner_payment_error_msg', 'prev_trans_status', 'prev_partner_payment_status', 'partner_item_ref_no', 'debit_account_name', 'refund_status', 'refund_date', 'province_name', 'bank_branch_name', 't24_fee_amount', 't24_value_date', 'isvirtual', 'sub_va_acct', 'processing_at', 'processing_flag', 'transfer_date', 'batch_payment_type', 'emailreceiver', 'processing_email', 'processing_email_pref', 'bactch_guiid', 'ordinal_number', 'des_acc_lio_bank', 'transaction_id_card', 'number_retry', 'retry_date', 'detail_guiid'] %}
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
