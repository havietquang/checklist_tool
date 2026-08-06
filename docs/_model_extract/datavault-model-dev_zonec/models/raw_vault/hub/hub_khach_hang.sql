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
tags                : ['bpm'] = filter khi run (dbt run --select tag:bpm)
====================================================================
*/
{{ config(
    alias = 'hub_khach_hang',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['khach_hang_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'phase1', 'all']
) }}

{% set source_name = 'bpm' %}
{% set unique_key = 'khach_hang_hashkey' %}

{% set raw_sql %}
WITH unioned_source AS (
    SELECT
        hashkey AS khach_hang_hashkey,
        CAST(id AS bigint) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'khach_hang') AS record_source,
        load_timestamp,
        1 AS source_priority
    FROM {{ ref('v_stg_bpm_khach_hang') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS khach_hang_hashkey,
        CAST(khach_hang_id AS bigint) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'khach_hang_ca_nhan') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_khach_hang_ca_nhan') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND khach_hang_id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS khach_hang_hashkey,
        CAST(khach_hang_id AS bigint) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'khach_hang_doanh_nghiep') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_khach_hang_doanh_nghiep') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND khach_hang_id IS NOT NULL
),
deduped AS (
    SELECT
        khach_hang_hashkey,
        business_key,
        source_event_date,
        record_source,
        load_timestamp,
        row_number() OVER (
            PARTITION BY khach_hang_hashkey
            ORDER BY source_priority
        ) AS rn
    FROM unioned_source
    WHERE business_key IS NOT NULL
      AND trim(CAST(business_key AS string)) <> ''
)
SELECT
    khach_hang_hashkey,
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
