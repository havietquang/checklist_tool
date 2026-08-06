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
unique_key          : Khóa định danh record (hub_hashkey + hashdiff)
skip_matched_step   : true = bỏ record không đổi → tăng performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['omni'] = filter khi run (dbt run --select tag:omni)
====================================================================
*/

{{ config(
    alias = 'sat_od_linked_deposit_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['od_registration_hashkey', 'hashdiff', 'source_event_date', 'ma_key'],
    skip_matched_step = true,
    tags = ['omni', 'od_registration', 'phase2', 'all']
) }}

{% set source_name = 'omni' %}
{% set source_table = 'od_linked_deposit' %}
{% set hub_hashkey = 'od_registration_hashkey' %}

{%- set raw_sql -%}
SELECT
    r.hashkey AS od_registration_hashkey,
    ld.hashdiff_od_linked_deposit_information AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS TIMESTAMP) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS STRING), '__', '{{ source_table }}') AS record_source,
    ld.ma_key,
    ld.deposit_balance,
    ld.maturity_date,
    ld.opening_date,
    ld.is_additional_request,
    ld.created_at,
    ld.created_by,
    ld.updated_at,
    ld.updated_by
FROM {{ ref('v_stg_omni_od_linked_deposit') }} ld
JOIN {{ ref('v_stg_omni_od_registration') }} r
    ON ld.od_registration_id = r.id
WHERE ld.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND r.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}
