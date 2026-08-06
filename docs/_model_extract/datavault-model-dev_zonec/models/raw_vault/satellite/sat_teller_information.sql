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
    alias = 'sat_teller_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['teller_hashkey', 'hashdiff', 'source_event_date'],
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
{% set source_table = 't24_teller' %}
{% set hashdiff_col = 'hashdiff_teller_information' %}
{% set hub_hashkey = 'teller_hashkey' %}
{% set source_model = 'v_stg_t24_t24_teller' %}
{% set list_cols = ['t_dr_cr_marker AS t_dr_cr_marker', 't_currency_1 AS t_currency_1', 't_amount_local_1 AS t_amount_local_1', 't_amount_fcy_1 AS t_amount_fcy_1', 't_rate_1 AS t_rate_1', 't_narrative_1 AS t_narrative_1', 't_value_date_1 AS t_value_date_1', 't_currency_2 AS t_currency_2', 't_amount_local_2 AS t_amount_local_2', 't_amount_fcy_2 AS t_amount_fcy_2', 't_rate_2 AS t_rate_2', 't_narrative_2 AS t_narrative_2', 't_value_date_2 AS t_value_date_2', 't_record_status AS t_record_status', 't_transaction_code AS t_transaction_code', 'sales_person AS sales_person','t_date_time as t_date_time', 't_account_1 as t_account_1', 't_account_2 as t_account_2'] %}
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

