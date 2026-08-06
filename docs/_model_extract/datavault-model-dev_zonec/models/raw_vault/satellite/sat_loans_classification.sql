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
    alias = 'sat_loans_classification',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['loans_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'loan', 'phase1', 'all']
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
{% set source_table = 't24_loans_and_deposits' %}
{% set hashdiff_col = 'hashdiff_loans_classification' %}
{% set hub_hashkey = 'loans_hashkey' %}
{% set source_model = 'v_stg_t24_t24_loans_and_deposits' %}
{% set list_cols = ['t_category AS t_category', 't_loan_subproduct AS t_loan_subproduct', 't_loan_method AS t_loan_method', 't_loan_purpose AS t_loan_purpose', 't_ld_cust_group AS t_ld_cust_group', 't_cu_cust_group AS t_cu_cust_group', 't_ocb_prod_main AS t_ocb_prod_main', 't_ocb_pro_bundle AS t_ocb_pro_bundle', 't_ocb_promotion AS t_ocb_promotion', 't_ocb_pro_partner AS t_ocb_pro_partner', 't_source_of_fund AS t_source_of_fund', 't_ocb_outof_area AS t_ocb_outof_area', 't_industry_lev1 AS t_industry_lev1', 't_industry_lev2 AS t_industry_lev2', 't_industry_lev3 AS t_industry_lev3', 't_industry_levo AS t_industry_levo', 't_industry_levt AS t_industry_levt', 't_liquidation_mode AS t_liquidation_mode', 't_extend_sch AS t_extend_sch', 't_vmb_class_date AS t_vmb_class_date', 't_extendsch_date AS t_extendsch_date', 't_annuity_pay_method AS t_annuity_pay_method', 't_ocb_ln_hold_yn AS t_ocb_ln_hold_yn'] %}
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

