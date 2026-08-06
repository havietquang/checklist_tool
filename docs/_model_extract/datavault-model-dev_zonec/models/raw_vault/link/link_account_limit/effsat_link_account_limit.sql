{{ config(
    alias = 'effsat_link_account_limit',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_account_limit_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'account', 'phase1', 'all']
) }}

{% set source_name = 't24' %}
{% set source_table = 't24_account' %}
{% set link_model = 'link_account_limit' %}
{% set unique_key = 'link_account_limit_hashkey' %}

{%- set raw_sql -%}
WITH limit_source AS (
    SELECT DISTINCT
        id,
        t_customer,
        t_limit_ref,
        CONCAT(
            CAST(t_customer AS string),
            '.',
            CONCAT(
                LPAD(get(SPLIT(CAST(t_limit_ref AS string), '\\.'), 0), 7, '0'),
                '.',
                get(SPLIT(CAST(t_limit_ref AS string), '\\.'), 1)
            )
        ) AS limit_business_key,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date
    FROM {{ ref('v_stg_t24_t24_account') }}
)
SELECT
    {{ hash_column(['id', 'limit_business_key'], source_name) }} AS link_account_limit_hashkey,
    source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM limit_source
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND id IS NOT NULL
  AND t_customer IS NOT NULL
  AND t_limit_ref IS NOT NULL
  AND t_limit_ref LIKE '%.%'
{%- endset %}

{{ effsat(
    unique_key = unique_key,
    link_model = link_model,
    raw_sql = raw_sql
) }}
