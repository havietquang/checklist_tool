{{ config(
    alias = 'effsat_link_crb_customer',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_crb_customer_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'crb', 'phase1', 'all', 'bv_zonec']
) }}

{% set source_name = 't24' %}
{% set source_table = 't24_crb' %}
{% set source_business_key_cols = ['tieukhoan', 'gl', 'cif'] %}
{% set link_model = 'link_crb_customer' %}
{% set unique_key = 'link_crb_customer_hashkey' %}

{%- set raw_sql -%}
SELECT DISTINCT
    {{ hash_column(source_business_key_cols, source_name) }} AS link_crb_customer_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_t24_t24_crb') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND tieukhoan IS NOT NULL
AND gl IS NOT NULL
AND cif IS NOT NULL
{%- endset %}

{{ effsat(
    unique_key = unique_key,
    link_model = link_model,
    raw_sql = raw_sql
) }}
