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
tags                : ['omnima'] = filter khi run (dbt run --select tag:omnima)
====================================================================
*/

{{ config(
    alias = 'sat_onbroading_cus_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['onbroading_cus_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['omnima', 'onboarding_cus', 'zonec']
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

{% set source_name = 'omnima' %}
{% set source_table = 'onboarding_cus' %}
{% set hashdiff_col = 'hashdiff_onbroading_cus_information' %}
{% set hub_hashkey = 'onbroading_cus_hashkey' %}
{% set source_model = 'v_stg_omnima_onboarding_cus' %}
{% set list_cols = ['creat_by', 'creat_dt', 'updt_by', 'updt_dt', 'birthday', 'crefnum', 'contact_address', 'contact_address_district', 'contact_address_province', 'contact_address_ward', 'custgroup_type', 'email', 'fullname', 'gender', 'is_exist_bankaccount', 'is_exist_debitcard', 'is_exist_ebuser', 'is_open_atm', 'is_receive_physicalcard', 'is_receive_virtualcard', 'legalidnum', 'legalidtype', 'legaliid_expired_date', 'legaliid_issued_date', 'legaliid_issued_location', 'marital_status', 'mobilenumber', 'nationality', 'prefnum', 'permanent_address', 'permanent_address_district', 'permanent_address_province', 'permanent_address_ward', 'professional_name', 'register_fail_date', 'register_status', 'trans_method', 'transaction_return', 'transaction_return_msg', 'input_date', 'cif', 'appsflyer_id', 'address_street_line', 'check_nfc_result', 'chip_photo_path', 'first_name', 'is_nfc', 'last_name', 'province_name', 'verify_id_chip_status'] %}
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
