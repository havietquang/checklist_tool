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
    alias = 'sat_crm_contact_notes_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['crm_contact_notes_hashkey', 'hashdiff', 'source_event_date'],
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
{% set source_table = 'crm_contact_notes' %}
{% set hashdiff_col = 'hashdiff_contact_notes_information' %}
{% set hub_hashkey = 'crm_contact_notes_hashkey' %}
{% set source_model = 'v_stg_crm_crm_contact_notes' %}
{% set list_cols = ['name as name', 'status as status', 'date_created as date_created', 'user_created as user_created', 'date_updated as date_updated', 'user_updated as user_updated', 'is_imported as is_imported', 'program_type as program_type', 'program_code as program_code', 'is_program_hot as is_program_hot', 'end_date_program as end_date_program', 'start_date_program as start_date_program', 'id_product as id_product', 'custgroup as custgroup', 'department as department', 'parent_key as parent_key', 'file_banner as file_banner', 'file_manual as file_manual', 'file_info_prod as file_info_prod', 'data_type as data_type', 'position as position'] %}
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

