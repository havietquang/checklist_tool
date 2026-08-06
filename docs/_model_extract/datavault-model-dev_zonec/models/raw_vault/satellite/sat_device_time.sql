{{ config(
    alias = 'sat_device_time',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['device_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['way4', 'device', 'phase1', 'all']
) }}

{% set source_name = 'way4' %}
{% set source_table = 'device_rec' %}
{% set hashdiff_col = 'hashdiff_device_time' %}
{% set hub_hashkey = 'device_hashkey' %}
{% set raw_sql -%}
SELECT
    hashkey AS device_hashkey,
    {{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(cast('{{source_name}}' as string), '__','{{source_table}}') as record_source,
    gmt_offset,
    time_from,
    time_to,
    working_time,
    cut_off_time
FROM {{ ref('v_stg_way4_device_rec') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND amnd_state = 'A'
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

