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
    alias = 'sat_security_position',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['security_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'security', 'phase2', 'all']
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
{% set source_table = 't24_security_position' %}
{% set hashdiff_col = 'hashdiff_security_position' %}
{% set hub_hashkey = 'security_hashkey' %}
{% set source_model = 'v_stg_t24_t24_security_position' %}
{% set list_cols = ['ma_key','t_book_cost_sec_ccy','t_cap_amt','t_closing_bal_no_nom','t_cost_invst_bse_ccy','t_cost_invst_ref_ccy','t_cost_invst_sec_ccy','t_date_last_traded','t_depository','t_fin_company','t_gr_bk_cost_sec_ccy','t_gross_cost_sec_ccy','t_held_since','t_income_curr_period','t_issue_date','t_nom_amt_blocked','t_opening_bal_no_nom','t_security_account','t_urlz_ccy_gn_cr_ptf','t_urlz_mrk_gn_cr_ptf','t_val_dat_book_cost','t_value_dat_cost_ref','t_value_dated_cost','t_value_dated_posn','t_ytd_invst_sec_ccy','t_amt_blocked','t_reference_number','t_nominee_code','t_maturity_date','t_interest_rate','t_opn_cost_invst_sec','t_opn_cost_invst_ptf'] %}
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

