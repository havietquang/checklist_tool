-- depends_on: {{ ref('v_stg_t24_t24_ocbh_industry_tt15') }}

{{ config(
    alias = 'ref_t24_ocbh_industry_tt15',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'entity', 'reference', 'phase2', 'all']
) }}

{% set raw_sql -%}
    SELECT
        sha2(('ocbh_industry_tt15' || cast(id as string)), 256) as ref_hashkey,
        id,
        t_industry_tt15_l1,
        t_industry_tt15_l2,
        t_industry_tt15_l3,
        t_industry_name,
        hashdiff_full as hashdiff,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
        CONCAT('t24', '__', 't24_ocbh_industry_tt15') AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM {{ ref('v_stg_t24_t24_ocbh_industry_tt15') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ raw_sql }}
