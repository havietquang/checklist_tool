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
    alias = 'sat_sec_trade_broker',
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
{% set hashdiff_col = 'hashdiff_sec_trade_broker' %}
{% set hub_hashkey = 'sec_trade_hashkey' %}
{% set source_model = 'v_stg_t24_t24_sec_trade' %}
{% set list_cols = ['t_broker_no AS t_broker_no', 't_broker_type AS t_broker_type', 't_br_acc_no AS t_br_acc_no', 't_br_gross_accr AS t_br_gross_accr', 't_br_gross_am_sec AS t_br_gross_am_sec', 't_br_gross_am_trd AS t_br_gross_am_trd', 't_br_intr_am_trd AS t_br_intr_am_trd', 't_br_no_nom AS t_br_no_nom', 't_br_price AS t_br_price', 't_br_tot_nom AS t_br_tot_nom', 't_br_trans_code AS t_br_trans_code'] %}
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

