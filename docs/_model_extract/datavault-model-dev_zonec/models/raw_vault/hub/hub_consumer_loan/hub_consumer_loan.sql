{{ config(
    alias = 'hub_consumer_loan',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['consumer_loan_hashkey'],
    skip_matched_step = true,
    tags = ['comb', 'zonec', 'all', 'bv_zonec']
) }}

{% set source_name = 'comb' %}
{% set unique_key = 'consumer_loan_hashkey' %}

{% set raw_sql %}
WITH unioned_source AS (
    SELECT
        hashkey AS consumer_loan_hashkey,
        contract_no AS business_key,
        source_event_date,
        CONCAT('comb', '__', 'consumer_loan') AS record_source,
        load_timestamp,
        1 AS source_priority
    FROM {{ ref('v_stg_comb_consumer_loan') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND contract_no IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS consumer_loan_hashkey,
        contract_no AS business_key,
        source_event_date,
        CONCAT('comb', '__', 'consumer_loan_wo') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_comb_consumer_loan_wo') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND contract_no IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS consumer_loan_hashkey,
        contract_no AS business_key,
        source_event_date,
        CONCAT('comb', '__', 'fact_collection_comb') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_comb_fact_collection_comb') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND contract_no IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS consumer_loan_hashkey,
        contractcode AS business_key,
        source_event_date,
        CONCAT('comb', '__', 'next_payment_amount') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_comb_next_payment_amount') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND contractcode IS NOT NULL
),
deduped AS (
    SELECT
        consumer_loan_hashkey,
        business_key,
        source_event_date,
        record_source,
        load_timestamp,
        row_number() OVER (
            PARTITION BY consumer_loan_hashkey
            ORDER BY source_priority
        ) AS rn
    FROM unioned_source
    WHERE business_key IS NOT NULL
)
SELECT
    consumer_loan_hashkey,
    business_key,
    source_event_date,
    record_source,
    load_timestamp
FROM deduped
WHERE rn = 1
{% endset %}

{{ hub(
    source_name = source_name,
    unique_key = unique_key,
    raw_sql = raw_sql
) }}
