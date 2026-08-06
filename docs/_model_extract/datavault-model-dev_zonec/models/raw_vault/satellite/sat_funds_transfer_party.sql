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
    alias = 'sat_funds_transfer_party',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['funds_transfer_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'transaction', 'phase1', 'all']
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
{% set source_table = 't24_funds_transfer' %}
{% set hashdiff_col = 'hashdiff_funds_transfer_party' %}
{% set hub_hashkey = 'funds_transfer_hashkey' %}
{% set source_model = 'v_stg_t24_t24_funds_transfer' %}
{% set list_cols = ['t_r_ci_code AS t_r_ci_code', 't_bidv_recvrbank AS t_bidv_recvrbank', 't_bidv_benbkcode AS t_bidv_benbkcode', 't_bidv_senderbank AS t_bidv_senderbank', 't_in_ben_customer AS t_in_ben_customer', 't_ordering_cust AS t_ordering_cust', 't_ben_customer AS t_ben_customer', 't_ben_our_charges AS t_ben_our_charges', 't_ocb_o_ci_code AS t_ocb_o_ci_code', 't_ocb_o_ci_name AS t_ocb_o_ci_name', 't_inw_send_bic AS t_inw_send_bic', 't_intermed_bank AS t_intermed_bank', 't_ben_bank_branch AS t_ben_bank_branch', 't_ordering_bank AS t_ordering_bank', 't_cu_d_ord_cpt AS t_cu_d_ord_cpt', 't_profit_centre_cust AS t_profit_centre_cust'] %}
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
    list_cols=list_cols,
    transaction_table=true
) }}

