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
    alias = 'sat_customer_contact',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['customer_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'entity', 'phase1', 'all']
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
{% set source_table = 't24_customer' %}
{% set hashdiff_col = 'hashdiff_customer_contact' %}
{% set hub_hashkey = 'customer_hashkey' %}
{% set source_model = 'v_stg_t24_t24_customer' %}
{% set list_cols = ['address AS address', 'ward_1 AS ward_1', 'town_country AS town_country', 'province_1 AS province_1', 'phone_1 AS phone_1', 'sms_1 AS sms_1', 'off_phone AS off_phone', 'email_1 AS email_1', 'contact_person AS contact_person', 'contact_title AS contact_title', 'status_contact AS status_contact', 'company_name AS company_name', 'bussiness_addr AS bussiness_addr', 'representative AS representative', 'represent_job AS represent_job', 'legal_id_deputy AS legal_id_deputy', 'country AS country', 'street AS street', 'add_num AS add_num', 'ward_2 AS ward_2', 'province_2 AS province_2', 'town_country_2 AS town_country_2', 'sms_2 AS sms_2', 'phone_2 AS phone_2', 'off_phone_2 AS off_phone_2'] %}
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

