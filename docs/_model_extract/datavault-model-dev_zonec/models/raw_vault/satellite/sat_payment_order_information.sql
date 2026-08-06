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
    alias = 'sat_payment_order_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['payment_order_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['omni', 'payment_order', 'phase2', 'all']
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
{% set source_table = 'payment_order' %}
{% set hashdiff_col = 'hashdiff_payment_order_information' %}
{% set hub_hashkey = 'payment_order_hashkey' %}
{% set source_model = 'v_stg_omni_payment_order' %}
{% set list_cols = ['account as account', 'name as name', 'amount as amount', 'currency as currency', 'orig_acc_currency as orig_acc_currency', 'send_to_core_datetime as send_to_core_datetime', 'delivery_date as delivery_date', 'rejection_reason as rejection_reason', 'reason_code as reason_code', 'reason_text as reason_text', 'error_description as error_description', 'address_line1 as address_line1', 'address_line2 as address_line2', 'street_name as street_name', 'town as town', 'country_sub_division as country_sub_division', 'post_code as post_code', 'country as country', 'arrangement_id as arrangement_id', 'ext_arrangement_id as ext_arrangement_id', 'service_agreement_id as service_agreement_id', 'additions as additions', 'payment_setup_id as payment_setup_id', 'approval_id as approval_id', 'payment_submission_id as payment_submission_id', 'confirmation_id as confirmation_id' , 'bank_reference_id as bank_reference_id', 'created_at', 'created_by', 'updated_at', 'updated_by'] %}
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

