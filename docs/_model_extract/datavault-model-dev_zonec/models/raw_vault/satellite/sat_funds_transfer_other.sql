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
    alias = 'sat_funds_transfer_other',
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
{% set hashdiff_col = 'hashdiff_funds_transfer_other' %}
{% set hub_hashkey = 'funds_transfer_hashkey' %}
{% set source_model = 'v_stg_t24_t24_funds_transfer' %}
{% set list_cols = ['t_ocb_tax_code AS t_ocb_tax_code', 't_ocb_bank_id AS t_ocb_bank_id', 't_ocb_smartlink AS t_ocb_smartlink', 't_ocb_ld_htls AS t_ocb_ld_htls','t_at_auth_code AS t_at_auth_code', 't_ocb_term_htls AS t_ocb_term_htls', 't_ocb_ben_acct AS t_ocb_ben_acct', 't_ocb_ben_cust AS t_ocb_ben_cust', 't_ocb_r_ci_name AS t_ocb_r_ci_name', 't_ocb_li_cont_id AS t_ocb_li_cont_id', 't_ocb_contra_ccy AS t_ocb_contra_ccy', 't_bk_to_bk_out AS t_bk_to_bk_out', 't_ben_name AS t_ben_name', 't_ocb_channel AS t_ocb_channel', 't_ocb_billi_code AS t_ocb_billi_code', 't_bc_bank_sort_code AS t_bc_bank_sort_code', 't_charge_code AS t_charge_code', 't_sending_addr AS t_sending_addr', 't_msg_narrative AS t_msg_narrative', 't_is_prepay AS t_is_prepay', 't_receiving_addr AS t_receiving_addr', 't_border_trans AS t_border_trans', 't_eft_country AS t_eft_country', 't_in_ordering_bk AS t_in_ordering_bk', 't_in_ben_name AS t_in_ben_name', 't_tax_code AS t_tax_code'] %}
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

