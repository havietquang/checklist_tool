{{ config(
    alias = 'effsat_link_letter_of_credit_limit',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_letter_of_credit_limit_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'trade_finance', 'phase1', 'all']
) }}

{% set source_name = 't24' %}
{% set source_table = 't24_letter_of_credit' %}
{% set link_model = 'link_letter_of_credit_limit' %}
{% set unique_key = 'link_letter_of_credit_limit_hashkey' %}

{%- set raw_sql -%}
WITH limit_source AS (
    SELECT DISTINCT
        id,
        T_APPLICANT_CUSTNO,
        t_limit_reference,
        CONCAT(
            CAST(T_APPLICANT_CUSTNO AS string),
            '.',
            CONCAT(
                LPAD(SPLIT(CAST(t_limit_reference AS string), '\\.')[0], 7, '0'),
                '.',
                SPLIT(CAST(t_limit_reference AS string), '\\.')[1]
            )
        ) AS limit_business_key,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date
    FROM {{ ref('v_stg_t24_t24_letter_of_credit') }}
)
SELECT
    {{ hash_column(['id', 'limit_business_key'], source_name) }} AS link_letter_of_credit_limit_hashkey,
    source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM limit_source
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND id IS NOT NULL
  AND T_APPLICANT_CUSTNO IS NOT NULL
  AND t_limit_reference IS NOT NULL
{%- endset %}

{{ effsat(
    unique_key = unique_key,
    link_model = link_model,
    raw_sql = raw_sql
) }}
