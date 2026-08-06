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
    alias = 'sat_collateral_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['collateral_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'collateral', 'phase2', 'all']
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
{% set hashdiff_col = 'hashdiff_collateral_information' %}
{% set hub_hashkey = 'collateral_hashkey' %}
{% set source_model = 'v_stg_t24_t24_collateral' %}
{% set list_cols = ['t_collateral_type AS t_collateral_type', 't_description AS t_description', 't_collateral_code AS t_collateral_code', 't_coll_status AS t_coll_status', 't_expiry_date AS t_expiry_date', 't_value_date AS t_value_date', 't_ocb_co_note AS t_ocb_co_note', 't_notes AS t_notes', 't_in_cluster AS t_in_cluster', 't_borrow_purpose AS t_borrow_purpose', 't_ld_cust_group AS t_ld_cust_group', 't_ocb_start_date AS t_ocb_start_date', 't_ocb_end_date AS t_ocb_end_date', 't_inputter AS t_inputter', 't_date_time AS t_date_time', 't_authoriser AS t_authoriser','T_CURRENCY AS T_CURRENCY', 't_application_id'] %}
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

