{{ config(
    alias = 'sat_client_add_data',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['client_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['way4', 'entity', 'phase1', 'all']
) }}

{% set source_name = 'way4' %}
{% set source_table = 'client' %}
{% set hashdiff_col = 'hashdiff_client_add_data' %}
{% set hub_hashkey = 'client_hashkey' %}
{% set raw_sql -%}
SELECT
    hashkey AS client_hashkey,
    {{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(cast('{{source_name}}' as string), '__','{{source_table}}') as record_source,
    add_info_01,
    add_info_02,
    add_info_03,
    add_info_04,
    add_date_01,
    add_date_02
FROM {{ ref('v_stg_way4_client') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND amnd_state = 'A'
{%- endset %}

{{ satellite(
    source_name=source_name,
    hub_hashkey=hub_hashkey,
    raw_sql=raw_sql
) }}

