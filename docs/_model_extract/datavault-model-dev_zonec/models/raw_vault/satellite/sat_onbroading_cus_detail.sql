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
    alias = 'sat_onbroading_cus_detail',
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
{% set hashdiff_col = 'hashdiff_onbroading_cus_detail' %}
{% set hub_hashkey = 'onbroading_cus_hashkey' %}
{% set source_model = 'v_stg_omnima_onboarding_cus' %}
{% set list_cols = ['legalidlabel1', 'legalidlabel2', 'number_failed_verify_selfie_liveness', 'number_failed_verify_selfie_sanity', 'sent_data_to_crm', 'lst_fatca', 'utm_source', 'card_bank_branch_code', 'card_holder_name', 'card_number', 'card_received_address', 'card_received_district_code', 'card_received_product_code', 'card_received_province_code', 'card_received_type', 'card_received_ward_code', 'step_open_debit_card', 'token_number', 'referral_code', 'old_legal_id_exist_status', 'verify_response', 'hyper_result', 'black_list', 'lognote', 'eb_package_type', 'deeplink', 'legalid_issued_location_code', 'newfo_transferred', 'appsflyer_pid', 'customer_updated_status_infor', 'customer_flow_type'] %}
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
