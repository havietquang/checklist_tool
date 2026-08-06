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
    alias = 'sat_loans_payment_due_overdue',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['loans_payment_due_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'loan', 'phase1', 'all', 'bv_zonec']
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
{% set source_table = 't24_payment_due' %}
{% set hashdiff_col = 'hashdiff_loans_payment_due_overdue' %}
{% set hub_hashkey = 'loans_payment_due_hashkey' %}
{% set source_model = 'v_stg_t24_t24_payment_due' %}
{% set list_cols = ['t_pay_type AS t_pay_type', 't_outstanding_amt AS t_outstanding_amt', 't_penalty_rate AS t_penalty_rate', 't_penalty_spread AS t_penalty_spread', 't_pay_amt_orig AS t_pay_amt_orig', 't_pay_amt_outs AS t_pay_amt_outs', 't_total_overdue_amt AS t_total_overdue_amt', 't_tot_ovrdue_type AS t_tot_ovrdue_type', 't_total_amt_to_repay AS t_total_amt_to_repay', 't_tot_od_type_amt AS t_tot_od_type_amt','t_penalty_key as t_penalty_key'] %}
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

