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
    alias = 'sat_forex_payment_swift',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['forex_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'forex', 'phase1', 'all']
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
{% set source_table = 't24_forex' %}
{% set hashdiff_col = 'hashdiff_forex_payment_swift' %}
{% set hub_hashkey = 'forex_hashkey' %}
{% set source_model = 'v_stg_t24_t24_forex' %}
{% set list_cols = ['t_r_ci_code AS t_r_ci_code', 't_ibps_bene AS t_ibps_bene', 't_receiving_addr AS t_receiving_addr', 't_ben_acct_no AS t_ben_acct_no', 't_cpy_corr_add AS t_cpy_corr_add', 't_cparty_bank_acc AS t_cparty_bank_acc', 't_cparty_corr_no AS t_cparty_corr_no', 't_send_confirmation AS t_send_confirmation', 't_send_payment AS t_send_payment', 't_send_advice AS t_send_advice', 't_ocb_is_tag57a AS t_ocb_is_tag57a', 't_address AS t_address', 't_transaction_ref_no AS t_transaction_ref_no', 't_trans_code AS t_trans_code', 't_mkfile_com AS t_mkfile_com'] %}
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

