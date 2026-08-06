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
    alias = 'sat_letter_of_credit_party',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['letter_of_credit_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'trade_finance', 'phase1', 'all']
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
{% set source_table = 't24_letter_of_credit' %}
{% set hashdiff_col = 'hashdiff_letter_of_credit_party' %}
{% set hub_hashkey = 'letter_of_credit_hashkey' %}
{% set source_model = 'v_stg_t24_t24_letter_of_credit' %}
{% set list_cols = ['t_applicant_custno AS t_applicant_custno', 't_applicant AS t_applicant', 't_beneficiary_custno AS t_beneficiary_custno', 't_beneficiary AS t_beneficiary', 't_advise_thru AS t_advise_thru', 't_mt710_57a AS t_mt710_57a', 't_advising_bk_custno AS t_advising_bk_custno', 't_advising_bk AS t_advising_bk', 't_applicant_bank AS t_applicant_bank', 't_issuing_bank_no AS t_issuing_bank_no', 't_issuing_bank AS t_issuing_bank', 't_third_party_custno AS t_third_party_custno', 't_third_party AS t_third_party', 't_external_reference AS t_external_reference', 't_old_lc_number AS t_old_lc_number', 't_link_ld_ref AS t_link_ld_ref', 't_port_lim_ref AS t_port_lim_ref'] %}
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

