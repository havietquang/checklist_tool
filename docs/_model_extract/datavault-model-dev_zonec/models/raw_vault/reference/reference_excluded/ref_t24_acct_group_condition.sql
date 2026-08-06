-- depends_on: {{ ref('v_stg_t24_t24_acct_group_condition') }}

{{ config(
    alias = 'ref_t24_acct_group_condition',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'account', 'reference', 'phase2', 'all']
) }}

{% set raw_sql -%}
    SELECT
        sha2(('acct_group_condition' || cast(id as string)), 256) as ref_hashkey,
        id,
        t_minimum_bal,
        t_curr_no,
        inputter,
        t_date_time,
        t_authoriser,
        hashdiff_full as hashdiff,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
        CONCAT('t24', '__', 't24_acct_group_condition') AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM {{ ref('v_stg_t24_t24_acct_group_condition') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ raw_sql }}
