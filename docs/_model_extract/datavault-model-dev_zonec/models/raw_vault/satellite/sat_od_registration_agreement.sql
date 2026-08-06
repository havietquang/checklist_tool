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
tags                : ['omni'] = filter khi run (dbt run --select tag:omni)
====================================================================
*/

{{ config(
    alias = 'sat_od_registration_agreement',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['od_registration_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['omni', 'od_registration', 'phase2', 'all']
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

{% set source_name = 'omni' %}
{% set source_table = 'od_registration' %}
{% set hashdiff_col = 'hashdiff_od_registration_agreement' %}
{% set hub_hashkey = 'od_registration_hashkey' %}
{% set source_model = 'v_stg_omni_od_registration' %}
{% set list_cols = ['contract_file_id AS contract_file_id', 'result_file_id AS result_file_id', 'approval_file_id AS approval_file_id', 'contract_bill_code AS contract_bill_code', 'first_approval_agreement_uuid AS first_approval_agreement_uuid', 'first_approval_bill_code AS first_approval_bill_code', 'second_approval_agreement_uuid AS second_approval_agreement_uuid', 'second_approval_bill_code AS second_approval_bill_code', 'ecm_approval_document_id AS ecm_approval_document_id', 'ecm_contract_document_id AS ecm_contract_document_id', 'prepare_certificate_request_id AS prepare_certificate_request_id', 'confirmation_id AS confirmation_id', 'approval_agreement_id AS approval_agreement_id'] %}
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

