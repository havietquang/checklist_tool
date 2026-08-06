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
    alias = 'sat_soa_cust_account_detail',
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
{% set hashdiff_col = 'hashdiff_soa_cust_account_detail' %}
{% set hub_hashkey = 'soa_cust_account_hashkey' %}
{% set source_model = 'v_stg_ocbchannel_soa_cust_account' %}
{% set list_cols = ['trans_type', 'status_trans', 'trans_date', 'user_approved', 'account_officer', 'num_authorize_level', 'account_name', 'err_message', 'serial_no', 'datetime_approved', 'mnemonic', 'short_name', 'user_deleted', 'datetime_deleted', 'override_msg', 'posting_restrict', 'description', 'from_date', 'to_date', 'locked_amount', 'pre_status', 'cif_account_officer', 'changed_info', 'partner_id', 'program', 'source', 'posting_restrict_reason', 'old_category', 'old_partner_id', 'package_date', 'ac_middle_man', 'email_sms_sent_date', 'cust_name', 'nice_acc_info', 'restrict_reason_why', 'restrict_reason_why_desc'] %}
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
