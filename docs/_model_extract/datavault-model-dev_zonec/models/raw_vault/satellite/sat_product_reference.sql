{{ config(
    alias = 'sat_product_reference',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['product_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['way4', 'product', 'phase1', 'all']
) }}

{% set source_name = 'way4' %}
{% set source_table = 'appl_product' %}
{% set hashdiff_col = 'hashdiff_product_reference' %}
{% set hub_hashkey = 'product_hashkey' %}
{% set raw_sql -%}
SELECT
    hashkey AS product_hashkey,
    {{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(cast('{{source_name}}' as string), '__','{{source_table}}') as record_source,
    tariff_domain_template,
    copy_from_product,
    base_product,
    parent_code,
    reporting_product,
    product_template
FROM {{ ref('v_stg_way4_appl_product') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND amnd_state = 'A'
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

