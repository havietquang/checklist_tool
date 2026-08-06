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
    alias = 'sat_md_deal_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['md_deal_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'trade_finance', 'phase1', 'all', 'bv_zonec']
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
{% set source_table = 't24_md_deal' %}
{% set hashdiff_col = 'hashdiff_md_deal_information' %}
{% set hub_hashkey = 'md_deal_hashkey' %}
{% set source_model = 'v_stg_t24_t24_md_deal' %}
{% set list_cols = ['t_currency AS t_currency', 't_deal_date AS t_deal_date', 't_value_date AS t_value_date', 't_maturity_date AS t_maturity_date', 't_deal_sub_type AS t_deal_sub_type', 't_category AS t_category', 't_reference_1 AS t_reference_1', 't_reference_2 AS t_reference_2', 't_text_1 AS t_text_1', 't_text_2 AS t_text_2', 't_no_def_exp AS t_no_def_exp', 't_local_oversea AS t_local_oversea', 't_ocb_serial_no AS t_ocb_serial_no', 't_ocb_ser_no_main AS t_ocb_ser_no_main', 't_benef_cust_1 AS t_benef_cust_1', 't_benef_cust_2 AS t_benef_cust_2', 't_ben_address AS t_ben_address', 't_bank_address AS t_bank_address', 't_status AS t_status', 't_advice_expiry_date AS t_advice_expiry_date', 't_country_risk AS t_country_risk', 't_country_exposure AS t_country_exposure', 't_receiving_bank AS t_receiving_bank', 't_overdue_status AS t_overdue_status', 't_charge_account AS t_charge_account', 't_ocb_charge_acct AS t_ocb_charge_acct', 't_fut_real_est AS t_fut_real_est', 't_prod_promo AS t_prod_promo', 't_bpm_disb_id AS t_bpm_disb_id', 't_limit_reference AS t_limit_reference'] %}
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

