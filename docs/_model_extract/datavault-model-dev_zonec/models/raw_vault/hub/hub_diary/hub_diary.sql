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
    alias = 'hub_diary',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['diary_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'security', 'phase2', 'all']
) }}

{% set source_name = 't24' %}
{% set unique_key = 'diary_hashkey' %}

{% set raw_sql %}
WITH unioned_source AS (
    SELECT
        hashkey AS diary_hashkey,
        id AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 't24_diary') AS record_source,
        load_timestamp,
        1 AS source_priority
    FROM {{ ref('v_stg_t24_t24_diary') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS diary_hashkey,
        split_part(id, '-', 1) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 't24_entitlement') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_t24_t24_entitlement') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND id IS NOT NULL
),
deduped AS (
    SELECT
        diary_hashkey,
        business_key,
        source_event_date,
        record_source,
        load_timestamp,
        row_number() OVER (
            PARTITION BY diary_hashkey
            ORDER BY source_priority
        ) AS rn
    FROM unioned_source
    WHERE business_key IS NOT NULL
      AND trim(CAST(business_key AS string)) <> ''
)
SELECT
    diary_hashkey,
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

-- Su dung hub macro voi cau lenh raw_sql tuy chinh
{{ hub(
    source_name = source_name,
    unique_key = unique_key,
    raw_sql = raw_sql
) }}
