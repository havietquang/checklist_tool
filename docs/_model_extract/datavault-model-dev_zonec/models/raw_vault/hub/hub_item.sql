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
tags                : ['way4'] = filter khi run (dbt run --select tag:way4)
====================================================================
*/
{{ config(
    alias = 'hub_item',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['item_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'accounting', 'phase2', 'all']
) }}

{% set source_name = 'way4' %}
{% set unique_key = 'item_hashkey' %}

{% set raw_sql %}
WITH unioned_source AS (
    SELECT
        hashkey AS item_hashkey,
        CAST(id AS bigint) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'ows_item') AS record_source,
        load_timestamp,
        1 AS source_priority
    FROM {{ ref('v_stg_way4_item') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND id IS NOT NULL

    UNION ALL

    SELECT
        {{ hash_column(['item__id'], source_name) }} AS item_hashkey,
        CAST(item__id AS bigint) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'ows_entry') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_way4_entry') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND item__id IS NOT NULL
),
deduped AS (
    SELECT
        item_hashkey,
        business_key,
        source_event_date,
        record_source,
        load_timestamp,
        row_number() OVER (
            PARTITION BY item_hashkey
            ORDER BY source_priority
        ) AS rn
    FROM unioned_source
    WHERE business_key IS NOT NULL
      AND trim(CAST(business_key AS string)) <> ''
)
SELECT
    item_hashkey,
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
