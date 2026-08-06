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
tags                : ['ocbchannel'] = filter khi run (dbt run --select tag:ocbchannel)
====================================================================
*/
{{ config(
    alias = 'hub_soa_ntdt_register',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['soa_ntdt_register_hashkey'],
    skip_matched_step = true,
    tags = ['ocbchannel', 'soa_ntdt_register', 'zonec']
) }}

{% set source_name = 'ocbchannel' %}
{% set unique_key = 'soa_ntdt_register_hashkey' %}

/*
========================================================================
RAW SQL
========================================================================
Hub duoc nap tu 2 nguon (UNION DISTINCT theo id):
  1. soa_ntdt_register.id                  (nguon chinh, priority 1)
  2. soa_ntdt_register_detail.register_id  (nguon phu,   priority 2)
Voi soa_ntdt_register_detail, cot `hashkey` cua staging la hash cua
business key rieng cua no nen phai hash lai register_id bang macro
hash_column de dam bao hashkey dong nhat voi nguon chinh.
Dedup bang row_number theo hashkey, uu tien nguon co priority nho hon.
========================================================================
*/

{% set raw_sql %}
WITH unioned_source AS (
    SELECT
        hashkey AS soa_ntdt_register_hashkey,
        id AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'soa_ntdt_register') AS record_source,
        load_timestamp,
        1 AS source_priority
    FROM {{ ref('v_stg_ocbchannel_soa_ntdt_register') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND id IS NOT NULL

    UNION ALL

    SELECT
        {{ hash_column(['register_id'], source_name) }} AS soa_ntdt_register_hashkey,
        register_id AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'soa_ntdt_register_detail') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_ocbchannel_soa_ntdt_register_detail') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND register_id IS NOT NULL
),
deduped AS (
    SELECT
        soa_ntdt_register_hashkey,
        business_key,
        source_event_date,
        record_source,
        load_timestamp,
        row_number() OVER (
            PARTITION BY soa_ntdt_register_hashkey
            ORDER BY source_priority
        ) AS rn
    FROM unioned_source
    WHERE business_key IS NOT NULL
      AND trim(CAST(business_key AS string)) <> ''
)
SELECT
    soa_ntdt_register_hashkey,
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
