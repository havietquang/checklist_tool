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
    alias = 'sat_md_deal_value',
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
{% set hashdiff_col = 'hashdiff_md_deal_value' %}
{% set hub_hashkey = 'md_deal_hashkey' %}
{% set source_model = 'v_stg_t24_t24_md_deal' %}
{% set list_cols = ['t_principal_amount AS t_principal_amount', 't_inv_amount AS t_inv_amount', 't_ocb_online_amt AS t_ocb_online_amt', 't_charge_date AS t_charge_date', 't_charge_curr AS t_charge_curr', 't_charge_account AS t_charge_account', 't_charge_code AS t_charge_code', 't_charge_amt AS t_charge_amt', 't_ocb_avg_fee AS t_ocb_avg_fee', 't_ocb_charge AS t_ocb_charge', 't_ocb_charge_acct AS t_ocb_charge_acct', 't_ocb_col_dt_spec AS t_ocb_col_dt_spec', 't_ocb_coll_period AS t_ocb_coll_period', 't_ocb_estim_due_d AS t_ocb_estim_due_d', 't_ocb_fee_adjust AS t_ocb_fee_adjust', 't_ocb_fee_end_dat AS t_ocb_fee_end_dat', 't_ocb_gtee_fee AS t_ocb_gtee_fee', 't_ocb_gtee_letter AS t_ocb_gtee_letter', 't_ocb_letter_fee AS t_ocb_letter_fee', 't_ocb_m_fee_rate AS t_ocb_m_fee_rate', 't_ocb_mgn_amount AS t_ocb_mgn_amount', 't_ocb_nonm_fee_r1 AS t_ocb_nonm_fee_r1', 't_ocb_nonm_fee_r2 AS t_ocb_nonm_fee_r2', 't_ocb_nonmargin1 AS t_ocb_nonmargin1', 't_ocb_nonmargin2 AS t_ocb_nonmargin2', 't_ocb_per_collect AS t_ocb_per_collect', 't_ocb_sch_date AS t_ocb_sch_date', 't_ocb_sch_code AS t_ocb_sch_code', 't_ocb_sch_amt AS t_ocb_sch_amt', 't_ocb_sch_ccy AS t_ocb_sch_ccy', 't_ocb_sch_acc AS t_ocb_sch_acc', 't_ocb_sch_rem AS t_ocb_sch_rem', 't_prin_movement AS t_prin_movement', 't_ocb_secured1 AS t_ocb_secured1', 't_ocb_secured2 AS t_ocb_secured2', 't_ocb_tot_fee AS t_ocb_tot_fee'] %}
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

