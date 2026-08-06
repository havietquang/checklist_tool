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
    alias = 'sat_limit_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['limit_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'limit', 'phase1', 'all']
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
{% set source_table = 't24_limit' %}
{% set hashdiff_col = 'hashdiff_limit_information' %}
{% set hub_hashkey = 'limit_hashkey' %}
{% set source_model = 'v_stg_t24_t24_limit' %}
{% set list_cols = ['t_limit_currency AS t_limit_currency', 't_collateral_code AS t_collateral_code', 't_collat_right AS t_collat_right', 't_maximum_secured AS t_maximum_secured', 't_maximum_unsecured AS t_maximum_unsecured', 't_expiry_date AS t_expiry_date', 't_limit_product AS t_limit_product', 't_liability_number AS t_liability_number', 't_approval_date AS t_approval_date', 't_fixed_variable AS t_fixed_variable', 't_internal_amount AS t_internal_amount', 't_maximum_total AS t_maximum_total', 't_online_limit_date AS t_online_limit_date', 't_online_limit AS t_online_limit', 't_total_os AS t_total_os', 't_avail_amt AS t_avail_amt', 't_other_secured AS t_other_secured', 't_collat_amount AS t_collat_amount', 't_secured_amt AS t_secured_amt', 't_available_marker AS t_available_marker', 't_os_ccy AS t_os_ccy', 't_os_amt AS t_os_amt', 't_allowed_comp AS t_allowed_comp', 't_product_allowed AS t_product_allowed', 't_inputter AS t_inputter', 't_authoriser AS t_authoriser', 't_disb_exp_date AS t_disb_exp_date', 't_record_parent AS t_record_parent', 't_credit_line AS t_credit_line', 't_notes AS t_notes', 't_review_frequency AS t_review_frequency', 't_reducing_limit AS t_reducing_limit', 't_account AS t_account'] %}
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

