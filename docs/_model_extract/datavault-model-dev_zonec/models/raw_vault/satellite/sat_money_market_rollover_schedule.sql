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
    alias = 'sat_money_market_rollover_schedule',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['money_market_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'money_market', 'phase1', 'all']
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
{% set source_table = 't24_money_market' %}
{% set hashdiff_col = 'hashdiff_money_market_rollover_schedule' %}
{% set hub_hashkey = 'money_market_hashkey' %}
{% set source_model = 'v_stg_t24_t24_money_market' %}
{% set list_cols = ['t_rollover_marker AS t_rollover_marker', 't_new_interest_rate AS t_new_interest_rate', 't_rollover_date AS t_rollover_date', 't_capitalisation AS t_capitalisation', 't_prin_increase AS t_prin_increase', 't_incr_eff_date AS t_incr_eff_date', 't_tot_interest_amt AS t_tot_interest_amt', 't_next_prin_amount AS t_next_prin_amount', 't_next_int_amount AS t_next_int_amount', 't_int_period_start AS t_int_period_start', 't_int_period_end AS t_int_period_end', 't_int_schedule AS t_int_schedule'] %}
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

