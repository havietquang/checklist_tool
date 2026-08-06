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
    alias = 'sat_onbroading_cus_onbroading',
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
{% set hashdiff_col = 'hashdiff_onbroading_cus_onbroading' %}
{% set hub_hashkey = 'onbroading_cus_hashkey' %}
{% set source_model = 'v_stg_omnima_onboarding_cus' %}
{% set list_cols = ['step_authorize_status', 'step_check_aml', 'executed_register', 'facematching_status', 'full_go_step', 'image_id_facematching', 'image_id_legalid', 'image_id_selfie', 'image_id_ocr', 'legalid_status', 'liveness_selfie_score', 'liveness_selfie_status', 'meeting_address', 'meeting_address_district', 'meeting_address_province', 'meeting_address_ward', 'meeting_bank_brank_code', 'meeting_date', 'meeting_time_from', 'meeting_time_to', 'meeting_type', 'number_failed_verify_legalid_sanity', 'number_failed_verify_legalid_tampering', 'number_failed_verify_selfie_sanity_liveness', 'meeting_note', 'ocrmatching_status', 'step_verify_ocr', 'sanity_legalid_score', 'sanity_legalid_status', 'sanity_legalid_verdit', 'sanity_selfie_score', 'sanity_selfie_status', 'sanity_selfie_verdit', 'step_verify_selfie', 'step_verify_facematching', 'step_verify_legalid', 'step_register_status', 'tampering_legalid_score', 'tampering_legalid_status', 'tampering_legalid_verdit'] %}
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
