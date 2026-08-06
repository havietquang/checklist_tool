-- depends_on: {{ ref('v_stg_t24_t24_lc_enrichment') }}

{{ config(
    alias = 'ref_t24_lc_enrichment',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_hashkey', 'hashdiff'],
    skip_matched_step = true,
    tags = ['t24', 'trade_finance', 'reference', 'phase2', 'all']
) }}

{% set raw_sql -%}
    SELECT
        sha2(('lc_enrichment' || cast(id as string)), 256) as ref_hashkey,
        id,
        t_operation,
        t_revocable,
        t_ucp_ind,
        t_part_ship,
        t_transship,
        t_reimburse,
        t_charges_from,
        t_party_chrgd,
        t_chrg_status,
        t_drawing_type,
        t_pay_method,
        t_coll_reply,
        t_chrg_period,
        t_imp_exp,
        t_pay_type,
        t_inco_terms,
        hashdiff_full as hashdiff,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
        CONCAT('t24', '__', 't24_lc_enrichment') AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM {{ ref('v_stg_t24_t24_lc_enrichment') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ raw_sql }}
