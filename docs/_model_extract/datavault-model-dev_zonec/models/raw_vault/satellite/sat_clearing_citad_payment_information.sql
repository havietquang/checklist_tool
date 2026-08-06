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
tags                : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/

{{ config(
    alias = 'sat_clearing_citad_payment_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['clearing_citad_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'transaction', 'phase1', 'all']
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

{% set source_name = 't24' %}
{% set source_table = 't24_vmbl_int_clr_citad' %}
{% set hashdiff_col = 'hashdiff_clearing_citad_payment_information' %}
{% set hub_hashkey = 'clearing_citad_hashkey' %}
{% set source_model = 'v_stg_t24_t24_vmbl_int_clr_citad' %}
{% set list_cols = ['t_trans_date as t_trans_date', 't_currency as t_currency', 't_amount as t_amount', 't_sending_name as t_sending_name', 't_sending_addr as t_sending_addr', 't_receiving_name as t_receiving_name', 't_receiving_addr as t_receiving_addr', 't_ben_acct_no as t_ben_acct_no', 't_payment_details as t_payment_details', 't_debit_acct_no as t_debit_acct_no', 't_credit_acct_no as t_credit_acct_no', 't_o_ci_code as t_o_ci_code', 't_r_ci_code as t_r_ci_code', 't_o_pci_code as t_o_pci_code', 't_r_pci_code as t_r_pci_code', 't_txn_ref as t_txn_ref', 't_stmt_no as t_stmt_no', 't_trans_ref as t_trans_ref'] %}
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

