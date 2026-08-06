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
    alias = 'sat_sc_trading_position_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['sc_trading_position_hashkey', 'hashdiff', 'source_event_date'],
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
{% set source_table = 't24_sc_trading_position' %}
{% set hashdiff_col = 'hashdiff_sc_trading_position_information' %}
{% set hub_hashkey = 'sc_trading_position_hashkey' %}
{% set source_model = 'v_stg_t24_t24_sc_trading_position' %}
{% set list_cols = ['t_dealer_book AS t_dealer_book', 't_security_ccy AS t_security_ccy', 't_settlement_ccy AS t_settlement_ccy', 't_current_position AS t_current_position', 't_consol_trading_bal AS t_consol_trading_bal', 't_cpn_accr AS t_cpn_accr', 't_cpn_accr_posted AS t_cpn_accr_posted', 't_cur_avg_price AS t_cur_avg_price', 't_disc_accr_posted AS t_disc_accr_posted', 't_discount_accrued AS t_discount_accrued', 't_cur_cost_position AS t_cur_cost_position', 't_cur_realized_pl AS t_cur_realized_pl', 't_reval_unreal_pl AS t_reval_unreal_pl', 't_revaluation_date AS t_revaluation_date', 't_date AS t_date', 't_date_last_traded AS t_date_last_traded', 't_settled_position AS t_settled_position', 't_value_dated_pos AS t_value_dated_pos', 't_v_dated_cpn_accr AS t_v_dated_cpn_accr', 't_v_dated_dis_acc AS t_v_dated_dis_acc', 't_v_date_cost_of_pos AS t_v_date_cost_of_pos', 't_v_date_real_profit AS t_v_date_real_profit', 't_position_key AS t_position_key', 't_tax_balance AS t_tax_balance', 't_security_code AS t_security_code'] %}
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

