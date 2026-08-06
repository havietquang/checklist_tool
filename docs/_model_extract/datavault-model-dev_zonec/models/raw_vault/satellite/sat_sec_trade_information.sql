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
    alias = 'sat_sec_trade_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['sec_trade_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'security', 'phase1', 'all']
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
{% set source_table = 't24_sec_trade' %}
{% set hashdiff_col = 'hashdiff_sec_trade_information' %}
{% set hub_hashkey = 'sec_trade_hashkey' %}
{% set source_model = 'v_stg_t24_t24_sec_trade' %}
{% set list_cols = ['price_type AS price_type', 'depository AS depository', 'trade_date AS trade_date', 'value_date AS value_date', 'market_type AS market_type', 'cust_trans_code AS cust_trans_code', 'ocb_order_date AS ocb_order_date', 'cust_nominee AS cust_nominee', 'cust_remarks AS cust_remarks', 'cust_act_susp_cat AS cust_act_susp_cat', 't_contract_no AS t_contract_no', 't_index_contract AS t_index_contract', 'ocb_altsin AS ocb_altsin', 'stock_exchange AS stock_exchange', 'issue_date AS issue_date', 'maturity_date AS maturity_date', 'cust_sec_acc AS cust_sec_acc', 'cust_acc_no AS cust_acc_no', 't_cpty_limit_ref AS t_cpty_limit_ref', 't_cu_account_ccy AS t_cu_account_ccy', 't_cust_acc_no AS t_cust_acc_no', 't_value_date_2 AS t_value_date_2', 'trade_ccy as trade_ccy'] %}
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

