-- depends_on: {{ ref('v_stg_t24_t24_denom_exchange') }}

{{ config(
    alias = 'ref_t24_denom_exchange',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'currency', 'reference', 'phase2', 'all']
) }}

{% set raw_sql -%}
    SELECT
        sha2(('denom_exchange' || cast(id as string)), 256) as ref_hashkey,
        id,
        data_date,
        t_denomination,
        t_denom_buy_rate,
        t_denom_sell_rate,
        t_denom_revl_rate,
        t_denom_rate_sprd,
        t_curr_no,
        t_inputter,
        t_date_time,
        t_authoriser,
        hashdiff_full as hashdiff,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
        CONCAT('t24', '__', 't24_denom_exchange') AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM {{ ref('v_stg_t24_t24_denom_exchange') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ raw_sql }}
