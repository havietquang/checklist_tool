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
    alias = 'sat_repo_deal',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['repo_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'repo', 'phase1', 'all']
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
{% set source_table = 't24_repo' %}
{% set hashdiff_col = 'hashdiff_repo_deal' %}
{% set hub_hashkey = 'repo_hashkey' %}
{% set source_model = 'v_stg_t24_t24_repo' %}
{% set list_cols = ['currency AS currency', 'principal_amount_1 AS principal_amount_1', 'principal_amount_2 AS principal_amount_2', 'new_nominal AS new_nominal', 'repo_rate AS repo_rate', 'repo_interest AS repo_interest', 'dirty_price AS dirty_price', 't_clean_price AS t_clean_price', 't_gross_amount AS t_gross_amount', 't_gross_amt_sec AS t_gross_amt_sec', 'accrued_int_amt AS accrued_int_amt', 'ocb_order_date AS ocb_order_date', 'send_payment AS send_payment', 't_mm_locref_name AS t_mm_locref_name', 'drawdown_account AS drawdown_account', 'prin_liq_acct AS prin_liq_acct', 'int_liq_acct AS int_liq_acct', 'new_cu_acct_no AS new_cu_acct_no', 'margin_portfolio AS margin_portfolio', 'total_settlemnt AS total_settlemnt', 'new_sec_code AS new_sec_code'] %}
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

