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
    alias = 'sat_customer_information',
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
{% set hashdiff_col = 'hashdiff_customer_information' %}
{% set hub_hashkey = 'customer_hashkey' %}
{% set source_model = 'v_stg_t24_t24_customer' %}
{% set list_cols = ['name_1 AS name_1', 'short_name AS short_name', 'name_2 AS name_2', 'family_name AS family_name', 'birth_incorp_date AS birth_incorp_date', 'gender AS gender', 'title AS title', 'nationality AS nationality', 'residence AS residence', 'education_level AS education_level', 'language AS language', 'cifcontactdate AS cifcontactdate', 'create_date AS create_date', 'inputter AS inputter', 'authoriser AS authoriser', 'occupation AS occupation', 'cu_profession AS cu_profession', 'job_title AS job_title', 'seniority AS seniority', 'imp_exp_busines AS imp_exp_busines', 'marital_status as marital_status', 'mnemonic AS mnemonic', 'target AS target', 'labour_number AS labour_number', 'given_names AS given_names', 'date_time as date_time'] %}
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

