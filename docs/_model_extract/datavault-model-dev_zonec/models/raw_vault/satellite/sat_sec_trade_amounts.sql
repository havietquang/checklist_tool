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
    alias = 'sat_sec_trade_amounts',
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
{% set hashdiff_col = 'hashdiff_sec_trade_amounts' %}
{% set hub_hashkey = 'sec_trade_hashkey' %}
{% set source_model = 'v_stg_t24_t24_sec_trade' %}
{% set list_cols = ['security_currency AS security_currency', 'ocb_yield AS ocb_yield', 'cu_gross_am_sec AS cu_gross_am_sec', 'cust_intr_amt AS cust_intr_amt', 'exch_rate_sec AS exch_rate_sec', 'exch_rate_trd AS exch_rate_trd', 'cust_price AS cust_price', 'cust_tot_nom AS cust_tot_nom', 'cu_gross_accr AS cu_gross_accr', 'cu_gross_am_trd AS cu_gross_am_trd', 'ocb_int_basic AS ocb_int_basic', 't_cu_net_am_trd AS t_cu_net_am_trd', 't_cu_ex_rate_ref AS t_cu_ex_rate_ref', 't_cu_amount_due AS t_cu_amount_due', 't_ocb_par_value AS t_ocb_par_value', 'interest_rate AS interest_rate', 'cust_no_nom AS cust_no_nom'] %}
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

