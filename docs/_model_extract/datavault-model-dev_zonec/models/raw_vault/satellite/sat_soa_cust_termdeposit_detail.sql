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
    alias = 'sat_soa_cust_termdeposit_detail',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['soa_cust_termdeposit_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['ocbchannel', 'soa_cust_termdeposit', 'zonec']
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
{% set source_table = 'soa_cust_termdeposit' %}
{% set hashdiff_col = 'hashdiff_soa_cust_termdeposit_detail' %}
{% set hub_hashkey = 'soa_cust_termdeposit_hashkey' %}
{% set source_model = 'v_stg_ocbchannel_soa_cust_termdeposit' %}
{% set list_cols = ['user_signed_1', 'user_signed_2', 'user_signed_3', 'user_signed_4', 'user_signed_5', 'debit_account', 'product', 'service_type', 'interest_rate', 'customer_name', 'trans_date', 'debit_account_name', 'account_officer_id', 'user_deleted', 'datetime_deleted', 'frequency', 'is_schedules', 'calculation_base', 'forward_backward', 'schedule_type', 'ref_officer_id', 'override_msg', 'joint_holder_cif_1', 'relation_code_1', 'joint_notes_1', 'joint_holder_cif_2', 'relation_code_2', 'joint_notes_2', 'user_created_t24', 'pi_key', 'roll_product', 'tutor_cif', 'processing_step', 'extra_info', 'sub_product', 'hdtg_dn_id', 'process_step', 'mobile_no', 'mobile_no_co_owner', 'debit_acc_type', 'deposit_prgm', 'cust_group', 'prefer_intt_rate', 'term_commit', 'maturity_date_commit', 'ocb_auth_level', 'ocb_hotro_xuly_id', 'ref_id', 'account_name', 'denominations', 'quantity', 'issuer_code', 'ref_no', 'voucher_code', 'voucher_interest_rate', 'voucher_trace_id'] %}
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
