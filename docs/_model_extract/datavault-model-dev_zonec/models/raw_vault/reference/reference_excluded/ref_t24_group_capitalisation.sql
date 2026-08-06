-- depends_on: {{ ref('v_stg_t24_t24_group_capitalisation') }}

{{ config(
    alias = 'ref_t24_group_capitalisation',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'account', 'reference', 'phase2', 'all']
) }}

{% set raw_sql -%}
    SELECT
        sha2(('group_capitalisation' || cast(id as string)), 256) as ref_hashkey,
        id,
        data_date,
        t_dr_cap_frequency,
        t_cr_cap_frequency,
        t_settle_acct_close,
        t_start_of_day_cap,
        hashdiff_full as hashdiff,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
        CONCAT('t24', '__', 't24_group_capitalisation') AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM {{ ref('v_stg_t24_t24_group_capitalisation') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ raw_sql }}
