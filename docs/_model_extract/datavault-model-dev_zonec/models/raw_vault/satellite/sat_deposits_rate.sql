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
    alias = 'sat_deposits_rate',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['deposit_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'deposit', 'phase1', 'all']
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
{% set source_table = 't24_az_account' %}
{% set hashdiff_col = 'hashdiff_deposits_rate' %}
{% set hub_hashkey = 'deposit_hashkey' %}
{% set source_model = 'v_stg_t24_t24_az_account' %}
{% set list_cols = ['t_interest_rate AS t_interest_rate', 't_sch_fixed_rate AS t_sch_fixed_rate', 't_org_int_rate AS t_org_int_rate', 't_rollover_int_rate AS t_rollover_int_rate', 't_calculation_base AS t_calculation_base', 't_pay_int_at_mat AS t_pay_int_at_mat', 't_early_rate AS t_early_rate', 't_early_red_int AS t_early_red_int', 't_ocb_auth_level AS t_ocb_auth_level', 't_ocb_ipre_date AS t_ocb_ipre_date', 't_ocb_intratetype AS t_ocb_intratetype'] %}
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

