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
    alias = 'sat_teller_vat',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['teller_hashkey', 'hashdiff', 'source_event_date'],
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
{% set source_table = 't24_teller' %}
{% set hashdiff_col = 'hashdiff_teller_vat' %}
{% set hub_hashkey = 'teller_hashkey' %}
{% set source_model = 'v_stg_t24_t24_teller' %}
{% set list_cols = ['t_contact_name AS t_contact_name', 't_tax_code AS t_tax_code', 't_vat_form AS t_vat_form', 't_vat_inv_serial AS t_vat_inv_serial', 't_vat_inv_code AS t_vat_inv_code', 't_nat_id_type AS t_nat_id_type', 't_national_id AS t_national_id', 't_nat_place_iss AS t_nat_place_iss', 't_nat_iss_date AS t_nat_iss_date', 't_vat_goods AS t_vat_goods', 't_vat_rate AS t_vat_rate', 't_vat_inv_date AS t_vat_inv_date', 't_net_amount AS t_net_amount', 't_charge_account AS t_charge_account', 't_charge_category AS t_charge_category', 't_chrg_amt_local AS t_chrg_amt_local', 't_cust_id AS t_cust_id', 't_cheque_number AS t_cheque_number'] %}
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

