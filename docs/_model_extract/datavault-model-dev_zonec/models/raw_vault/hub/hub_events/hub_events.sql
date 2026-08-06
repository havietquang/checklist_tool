/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record (thuong: hub_hashkey + hashdiff)
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['clevertap'] = filter khi run (dbt run --select tag:clevertap)
====================================================================
*/
{{ config(
    alias = 'hub_events',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['events_hashkey'],
    skip_matched_step = true,
    tags = ['clevertap', 'event', 'phase2', 'all']
) }}

{% set source_name = 'clevertap' %}
{% set source_table = 'events' %}

{% set raw_sql -%}
SELECT
    hashkey AS events_hashkey,
    ts as ts,
    eventName as eventName,
    eventProps as eventProps,
    profile:identity as identity, -- extract from column profile
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT('{{ source_name }}' , '__', '{{ source_table }}') AS record_source,
    current_timestamp AS load_timestamp
FROM {{ ref('v_stg_clevertap_events') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ hub(raw_sql = raw_sql, source_name = source_name, source_table = source_table) }}

