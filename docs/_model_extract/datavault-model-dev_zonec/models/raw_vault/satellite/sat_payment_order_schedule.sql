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
    alias = 'sat_payment_order_schedule',
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
{% set hashdiff_col = 'hashdiff_payment_order_schedule' %}
{% set hub_hashkey = 'payment_order_hashkey' %}

{% set raw_sql -%}
SELECT
    hashkey AS payment_order_hashkey,
    {{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(cast('{{source_name}}' as string), '__','{{source_table}}') as record_source,
    requested_exec_date as requested_exec_date,
    start_date as start_date,
    end_date as end_date,
    frequency as frequency,
    every as every,
    when_execute as when_execute,
    repetition as repetition,
    remaining_occurrences as remaining_occurrences,
    non_working_day_strategy as non_working_day_strategy
FROM {{ ref('v_stg_omni_payment_order') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd') AND pmt_mode = 'RECURRING'
{%- endset %}

-- Su dung satellite macro voi cau lenh raw_sql tuy chinh
{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

