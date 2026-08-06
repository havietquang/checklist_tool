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
    alias = 'sat_collateral_valuation',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['collateral_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'collateral', 'phase1', 'all']
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
{% set source_table = 't24_collateral' %}
{% set hashdiff_col = 'hashdiff_collateral_valuation' %}
{% set hub_hashkey = 'collateral_hashkey' %}
{% set source_model = 'v_stg_t24_t24_collateral' %}
{% set list_cols = ['t_nominal_value AS t_nominal_value', 't_execution_value AS t_execution_value', 't_gen_ledger_value AS t_gen_ledger_value', 't_central_bank_value AS t_central_bank_value', 't_coll_price AS t_coll_price', 't_coll_number AS t_coll_number', 't_maximum_value AS t_maximum_value', 't_loan_ratio AS t_loan_ratio', 't_ocb_val_date AS t_ocb_val_date', 't_ocb_val_agent AS t_ocb_val_agent', 't_ocb_reval_date AS t_ocb_reval_date', 't_ocb_reval_agent AS t_ocb_reval_agent', 't_ocb_reval_amt AS t_ocb_reval_amt', 't_reval_next_date AS t_reval_next_date', 't_ocb_pric_date AS t_ocb_pric_date', 't_ocb_pric_organ AS t_ocb_pric_organ', 't_ocb_next_date AS t_ocb_next_date', 't_ocb_is_revalu AS t_ocb_is_revalu', 't_ocb_coll_rls AS t_ocb_coll_rls', 't_ocb_pric_val_rl AS t_ocb_pric_val_rl', 't_ocb_pric_dat_rl AS t_ocb_pric_dat_rl', 't_ocb_pric_or_rls AS t_ocb_pric_or_rls'] %}
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

