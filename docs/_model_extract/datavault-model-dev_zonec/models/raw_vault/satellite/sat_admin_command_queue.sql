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
tags                : ['ocbchannel'] = filter khi run (dbt run --select tag:ocbchannel)
====================================================================
*/

{{ config(
    alias = 'sat_admin_command_queue',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['admin_command_queue_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['ocbchannel', 'admin_command_queue', 'zonec']
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

{% set source_name = 'ocbchannel' %}
{% set source_table = 'admin_command_queue' %}
{% set hashdiff_col = 'hashdiff_admin_command_queue' %}
{% set hub_hashkey = 'admin_command_queue_hashkey' %}
{% set source_model = 'v_stg_ocbchannel_admin_command_queue' %}
{% set list_cols = ['comamnd_type_id', 'branch_code', 'user_input', 'date_input', 'status', 'user_authorised', 'date_authorised', 'notes', 'cust_id', 'full_name', 'represent_name', 'represent_tittle', 'new_user_name', 'new_password', 'new_package_type', 'new_authentication_type', 'new_mobile', 'new_user_type', 'new_user_role', 'new_user_group', 'hard_token_seri_no', 'old_package_type', 'old_mobile', 'user_id', 'channel', 'fee_account', 'rm_code_name', 'is_restrict_acc_access', 'restrict_access_acc_list', 'json_val', 'is_sequen', 'fee_status'] %}
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
