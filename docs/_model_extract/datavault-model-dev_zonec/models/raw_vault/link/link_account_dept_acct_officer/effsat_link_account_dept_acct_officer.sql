{{ config(
    alias = 'effsat_link_account_dept_acct_officer',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_account_dept_acct_officer_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'account', 'phase1', 'all']
) }}

{% set source_model = 'v_stg_t24_t24_account' %}
{% set source_name = 't24' %}
{% set source_table = 't24_account' %}
{% set link_model = 'link_account_dept_acct_officer' %}
{% set unique_key = 'link_account_dept_acct_officer_hashkey' %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(['id', 't_account_officer'], source_name) }} AS link_account_dept_acct_officer_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT('{{ source_name }}', '__', '{{ source_table }}') AS record_source,
    current_timestamp AS load_timestamp
FROM {{ ref(source_model) }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND id IS NOT NULL
  AND t_account_officer IS NOT NULL
  AND t_account_officer <> '0'
{%- endset %}

{{ effsat(
    unique_key = unique_key,
    link_model = link_model,
    raw_sql = raw_sql
) }}
