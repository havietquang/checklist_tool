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
    alias = 'sat_funds_transfer_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['funds_transfer_hashkey', 'hashdiff', 'source_event_date'],
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
{% set source_table = 't24_funds_transfer' %}
{% set hashdiff_col = 'hashdiff_funds_transfer_information' %}
{% set hub_hashkey = 'funds_transfer_hashkey' %}
{% set source_model = 'v_stg_t24_t24_funds_transfer' %}
{% set list_cols = ['t_transaction_type AS t_transaction_type', 't_record_status AS t_record_status', 't_ocb_cont_value AS t_ocb_cont_value', 't_ocb_tot_val_use AS t_ocb_tot_val_use', 't_ocb_value_use AS t_ocb_value_use', 't_ocb_contract_no AS t_ocb_contract_no', 't_online_ref_id AS t_online_ref_id', 't_debit_value_date AS t_debit_value_date', 't_debit_amount AS t_debit_amount', 't_amount_debited AS t_amount_debited', 't_loc_amt_debited AS t_loc_amt_debited', 't_debit_their_ref AS t_debit_their_ref', 't_credit_value_date AS t_credit_value_date', 't_credit_amount AS t_credit_amount', 't_amount_credited AS t_amount_credited', 't_loc_amt_credited AS t_loc_amt_credited', 't_credit_their_ref AS t_credit_their_ref', 't_payment_details AS t_payment_details', 't_debit_currency AS t_debit_currency', 't_credit_currency AS t_credit_currency', 't_clearing_id as t_clearing_id','t_debit_acct_no as t_debit_acct_no','t_credit_acct_no as t_credit_acct_no'] %}
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
    list_cols=list_cols,
    transaction_table=true
) }}

