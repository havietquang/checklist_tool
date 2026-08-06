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
tags                : ['crm'] = filter khi run (dbt run --select tag:crm)
====================================================================
*/

{{ config(
    alias = 'sat_crm_contact_hist_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['crm_contact_hist_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['crm', 'contact', 'phase2', 'all']
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

{% set source_name = 'crm' %}
{% set source_table = 'crm_contact_hist' %}
{% set hashdiff_col = 'hashdiff_contact_hist_information' %}
{% set hub_hashkey = 'crm_contact_hist_hashkey' %}
{% set source_model = 'v_stg_crm_crm_contact_hist' %}
{% set list_cols = ['CIF','DATE_CONTACT','FUNC_GROUP','BRANCH_CODE','NOTES','SOUCRE','CONTACT_STATUS_ID','CONTACT_TYPE_ID','CONTACT_RESULT_ID','CONTACTNOTEID','IMPORT_ID','PROGRAM_NOTYFY_ID','SALE_CODE','PROMISE_DATE','RECALL_DATE','CONDITION_DATE','REFERENCES_DATE','DIALID','DATETIME_CREATED','DATETIME_UPDATED','USER_CREATED','USER_UPDATED','UPDATE_TIMES'] %}
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

