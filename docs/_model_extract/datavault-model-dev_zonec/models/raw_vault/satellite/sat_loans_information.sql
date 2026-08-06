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
    alias = 'sat_loans_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['loans_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'loan', 'phase1', 'all', 'bv_zonec']
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
{% set hashdiff_col = 'hashdiff_loans_information' %}
{% set hub_hashkey = 'loans_hashkey' %}
{% set source_model = 'v_stg_t24_t24_loans_and_deposits' %}
{% set list_cols = ['t_legacy_ref AS t_legacy_ref', 't_link_reference AS t_link_reference', 't_vmb_ln_class AS t_vmb_ln_class', 't_ln_class_manual AS t_ln_class_manual', 't_status AS t_status', 't_ocb_class_covid AS t_ocb_class_covid', 't_amount AS t_amount', 't_drawdown_net_amt AS t_drawdown_net_amt', 't_purpose_amt AS t_purpose_amt', 't_amount_increase AS t_amount_increase', 't_ocb_ln_hold_cif AS t_ocb_ln_hold_cif', 't_drawdown_account AS t_drawdown_account', 't_ocb_ln_hold_rel AS t_ocb_ln_hold_rel','t_doubtful_sta as t_doubtful_sta', 't_currency as t_currency', 't_linked_tfdr_ref as t_linked_tfdr_ref','t_fee_pay_account as t_fee_pay_account','t_prin_liq_acct as t_prin_liq_acct','t_int_liq_acct as t_int_liq_acct','t_limit_reference as t_limit_reference'] %}
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

