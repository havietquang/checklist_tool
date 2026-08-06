{{ config(
    alias = 'sat_acnt_contract_scan',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['acnt_contract_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase2', 'all']
) }}

{% set source_name = 'way4' %}
{% set source_table = 'ows_acnt_contract' %}
{% set hashdiff_col = 'hashdiff_acnt_contract_scan' %}
{% set hub_hashkey = 'acnt_contract_hashkey' %}

{% set raw_sql -%}
SELECT
    hashkey AS acnt_contract_hashkey,
    {{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(cast('{{source_name}}' as string), '__','{{source_table}}') as record_source,
    last_scan
FROM {{ ref('v_stg_way4_acnt_contract') }}
WHERE amnd_state = 'A' AND source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}
