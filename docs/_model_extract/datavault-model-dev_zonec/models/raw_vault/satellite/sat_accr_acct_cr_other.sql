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
    alias = 'sat_accr_acct_cr_other',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['account_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'account', 'phase2', 'all']
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
{% set source_table = 't24_accr_acct_cr' %}
{% set hashdiff_col = 'hashdiff_accr_acct_cr_other' %}
{% set hub_hashkey = 'account_hashkey' %}
{% set source_model = 'v_stg_t24_t24_accr_acct_cr' %}
{% set list_cols = ['t_cr_int_tax_code', 't_cr_int_tax_rate', 't_cr_int_tax_amt', 't_cr_int_taxcateg', 't_cr_int_taxtrsdr', 't_cr_int_taxtrscr', 't_tax_for_customer', 't_tax_for_bank', 't_ica_post_interest', 't_ica_main_acct', 't_ica_dist_type', 't_ica_dist_ratio', 't_ica_int_categ', 't_ica_tr_ac', 't_ica_tr_pl', 't_ica_main_int', 't_ica_sub_int', 't_correction_number', 't_unadj_total_int', 't_tax_exch_rate', 't_manual_adj_amt', 't_correction_id', 't_adj_int_amt', 't_adj_tax_amt', 't_withheld_int_amt', 't_db_netting_amt', 't_correction_date'] %}
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
