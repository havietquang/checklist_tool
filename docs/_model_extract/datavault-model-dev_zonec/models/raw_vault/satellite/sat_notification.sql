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
    alias = 'sat_notification',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['notification_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['omni', 'notification', 'phase1', 'all']
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
{% set source_table = 'user_notification' %}
{% set cols_name = ['a.created_on', 'a.effective_date', 'a.severity_level', 'a.title', 'a.message',' b.acknowledgement_code']%}
{% set hashdiff_col = hash_column(cols_name,source_name) %}
{% set hub_hashkey = 'notification_hashkey' %}

{% set raw_sql -%}
SELECT
    a.hashkey AS notification_hashkey,
    {{ hashdiff_col }} AS hashdiff, 
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(cast('{{source_name}}' as string), '__','{{source_table}}') as record_source,
    a.created_on AS created_on,
    a.effective_date AS effective_date,
    a.severity_level AS severity_level,
    a.title AS title,
    a.message AS message,
    b.acknowledgement_code AS acknowledgement_code
FROM {{ ref('v_stg_omni_user_notification') }} a
LEFT JOIN {{ ref('v_stg_omni_acknowledgement') }} b 
ON  a.internal_user_id = b.internal_user_id and b.notification_id = a.id
WHERE a.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

-- Su dung satellite macro voi cau lenh raw_sql tuy chinh
{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

