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
    alias = 'sat_re_stat_line_bal',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['re_stat_line_bal_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'accounting', 'phase1', 'all']
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
{% set source_table = 't24_re_stat_line_bal' %}
{% set hashdiff_col = 'hashdiff_re_stat_line_bal' %}
{% set hub_hashkey = 're_stat_line_bal_hashkey' %}
{% set source_model = 'v_stg_t24_t24_re_stat_line_bal' %}
{% set list_cols = ['t_open_bal', 't_open_bal_lcl', 't_cr_movement', 't_cr_mvmt_lcl', 't_db_movement', 't_db_mvmt_lcl', 't_closing_bal', 't_closing_bal_lcl', 't_cr_mvmt_ytd', 't_cr_mvmt_ytd_lcl', 't_db_mvmt_ytd', 't_db_mvmt_ytd_lcl', 't_cr_mvmt_mth', 't_cr_mvmt_mth_lcl', 't_db_mvmt_mth', 't_db_mvmt_mth_lcl'] %}
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

