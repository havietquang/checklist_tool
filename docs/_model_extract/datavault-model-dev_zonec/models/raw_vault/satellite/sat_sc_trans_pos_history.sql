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
    alias = 'sat_sc_trans_pos_history',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['sc_trading_position_hashkey', 'hashdiff', 'source_event_date'],
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
{% set source_table = 't24_sc_trans_pos_history' %}
{% set hashdiff_col = 'hashdiff_sc_trans_pos_history' %}
{% set hub_hashkey = 'sc_trading_position_hashkey' %}
{% set source_model = 'v_stg_t24_t24_sc_trans_pos_history' %}
{% set list_cols = ['t_security_ccy','t_curr_per_st_date','t_sop_position','t_sop_avg_price','t_sop_cost_position','t_close_bus_date','t_cob_position','t_cob_avg_price','t_cob_cost_position','t_ptd_real_pl_posted','t_ptd_real_pl_calc','t_ptd_da_calc','t_trade_date','t_pos_date_time','t_trade_ref','t_trans_type','t_nominal','t_clean_price','t_consid','t_accr_interest','t_value_date','t_trd_disc_accr'] %}
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
