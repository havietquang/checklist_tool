/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
incremental_strategy: 'merge' = upsert theo unique_key
unique_key          : Khoa dinh danh record
skip_matched_step   : true = bo record khong doi -> tang performance
tags                : ['clevertap'] = filter khi run (dbt run --select tag:clevertap)
====================================================================
*/

{{ config(
    alias = 'sat_events_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['events_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['clevertap', 'event', 'phase2', 'all']
) }}

-- Extraction
{% set source_name = 'clevertap' %}
{% set source_table = 'events' %}
{% set hub_hashkey = 'events_hashkey' %}
{%- set raw_sql -%}
SELECT
    hashkey as events_hashkey,
    hashdiff_events_information AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    profile AS profile,
    deviceInfo AS deviceInfo

FROM {{ ref('v_stg_clevertap_events') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}
-------------

--Main part
{{ satellite(hub_hashkey=hub_hashkey, raw_sql=raw_sql, source_name=source_name) }}
