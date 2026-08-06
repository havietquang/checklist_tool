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
unique_key          : Khóa định danh record (hub_hashkey + ma_key cho MAS)
skip_matched_step   : true = bỏ record không đổi → tăng performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['omni'] = filter khi run (dbt run --select tag:omni)
====================================================================
*/

{{ config(
    alias = 'sat_device_detail',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['device_omni_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['omni', 'device', 'phase2', 'all']
) }}

/*
========================================================================
MULTI ACTIVE SATELLITE MACRO PARAMETERS
========================================================================
  - source_name  : Tên hệ thống nguồn, dùng để tạo giá trị cho cột `record_source`.
  - source_table : Tên bảng nghiệp vụ ở hệ thống nguồn.
  - hub_hashkey  : Tên khóa hash dùng để liên kết về bảng Hub (device_omni_hashkey).
  - ma_key       : Multi Active Business Key - phân biệt nhiều record cho cùng 1 hub entity.
  - raw_sql      : SQL tùy chỉnh vì cần JOIN giữa device và device_detail.
========================================================================
*/

{% set source_name = 'omni' %}
{% set source_table = 'device_detail' %}
{% set hub_hashkey = 'device_omni_hashkey' %}
{% set hashdiff_col = 'b.hashdiff_device_detail' %}

{% set raw_sql -%}
SELECT
    a.hashkey AS device_omni_hashkey,
    b.ma_key AS ma_key,
    {{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS STRING), '__', '{{ source_table }}') AS record_source,
    b.nfc_enabled AS nfc_enabled,
    b.omni_version AS omni_version,
    b.os_version AS os_version,
    b.unique_device_id AS unique_device_id
FROM {{ ref('v_stg_omni_device') }} a
LEFT JOIN {{ ref('v_stg_omni_device_detail') }} b
    ON a.device_id = b.device_id
WHERE a.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND b.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

