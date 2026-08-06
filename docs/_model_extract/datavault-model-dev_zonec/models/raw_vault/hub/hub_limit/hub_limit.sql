/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record (thuong: hub_hashkey + hashdiff)
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/
{{ config(
    alias = 'hub_limit',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['limit_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'limit', 'phase1', 'all']
) }}

{% set source_name = 't24' %}
{% set unique_key = 'limit_hashkey' %}
{% set raw_sql %}
WITH unioned_source AS (
    SELECT
        hashkey AS limit_hashkey,
        id AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 't24_limit') AS record_source,
        load_timestamp,
        1 AS source_priority
    FROM {{ ref('v_stg_t24_t24_limit') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND id IS NOT NULL

    UNION ALL

    SELECT
        {{ hash_column(['limit_business_key'], source_name) }} AS limit_hashkey,
        limit_business_key AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 't24_account') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM (
        SELECT
            CONCAT(
                CAST(t_customer AS string),
                '.',
                CONCAT(
                    LPAD(get(SPLIT(CAST(t_limit_ref AS string), '\\.'), 0), 7, '0'),
                    '.',
                    get(SPLIT(CAST(t_limit_ref AS string), '\\.'), 1)
                )
            ) AS limit_business_key,
            source_event_date,
            load_timestamp
        FROM {{ ref('v_stg_t24_t24_account') }}
        WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
          AND t_customer IS NOT NULL
          AND t_limit_ref IS NOT NULL
          AND t_limit_ref LIKE '%.%'
    )

    UNION ALL

    SELECT
        {{ hash_column(['limit_business_key'], source_name) }} AS limit_hashkey,
        limit_business_key AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 't24_loans_and_deposits') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM (
        SELECT
            CONCAT(
                CAST(t_customer_id AS string),
                '.',
                CONCAT(
                    LPAD(SPLIT(CAST(t_limit_reference AS string), '\\.')[0], 7, '0'),
                    '.',
                    SPLIT(CAST(t_limit_reference AS string), '\\.')[1]
                )
            ) AS limit_business_key,
            source_event_date,
            load_timestamp
        FROM {{ ref('v_stg_t24_t24_loans_and_deposits') }}
        WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
          AND t_customer_id IS NOT NULL
          AND t_limit_reference IS NOT NULL
    )

    UNION ALL

    SELECT
        {{ hash_column(['limit_business_key'], source_name) }} AS limit_hashkey,
        limit_business_key AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 't24_letter_of_credit') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM (
        SELECT
            CONCAT(
                CAST(t_applicant_custno AS string),
                '.',
                CONCAT(
                    LPAD(SPLIT(CAST(t_limit_reference AS string), '\\.')[0], 7, '0'),
                    '.',
                    SPLIT(CAST(t_limit_reference AS string), '\\.')[1]
                )
            ) AS limit_business_key,
            source_event_date,
            load_timestamp
        FROM {{ ref('v_stg_t24_t24_letter_of_credit') }}
        WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
          AND t_applicant_custno IS NOT NULL
          AND t_limit_reference IS NOT NULL
    )

    UNION ALL

    SELECT
        {{ hash_column(['limit_business_key'], source_name) }} AS limit_hashkey,
        limit_business_key AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 't24_collateral_right') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM (
        SELECT
            explode(split(CAST(t_limit_reference AS string), '::')) AS limit_business_key,
            source_event_date,
            load_timestamp
        FROM {{ ref('v_stg_t24_t24_collateral_right') }}
        WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
          AND t_limit_reference IS NOT NULL
    )
),
deduped AS (
    SELECT
        limit_hashkey,
        business_key,
        source_event_date,
        record_source,
        load_timestamp,
        row_number() OVER (
            PARTITION BY limit_hashkey
            ORDER BY source_priority
        ) AS rn
    FROM unioned_source
    WHERE business_key IS NOT NULL
      AND trim(CAST(business_key AS string)) <> ''
)
SELECT
    limit_hashkey,
    business_key,
    source_event_date,
    record_source,
    load_timestamp
FROM deduped
WHERE rn = 1
{% endset %}
/*
========================================================================
HUB MACRO PARAMETERS
========================================================================
  - source_model : Ten cua model/view nguon. VD: 'v_stg_t24_t24_ac_locked_events'.
  - source_name  : Ten he thong nguon (Record Source).
  - source_table : Ten bang nguon business duoc dua vao metadata.
  - unique_key   : Ten cot Hash Key cua Hub (Primary Key cua bang Hub).
  - business_key : Ten cot Business Key tu nguon.
========================================================================
*/

{{ hub(
    source_name = source_name,
    unique_key = unique_key,
    raw_sql = raw_sql
) }}
