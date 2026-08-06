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
    alias = 'hub_ocb_bill_services',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['ocb_bill_services_hashkey'],
    skip_matched_step = true,
    tags = ['ocbchannel', 'ocb_bill_services', 'zonec']
) }}

{% set source_name = 'ocbchannel' %}
{% set unique_key = 'ocb_bill_services_hashkey' %}

/*
========================================================================
RAW SQL
========================================================================
Hub duoc nap tu 2 nguon (UNION DISTINCT theo service_id):
  1. ocb_bill_services.service_id         (nguon chinh, priority 1)
  2. ocb_bill_service_provider.service_id (nguon phu,   priority 2)
Ca 2 staging deu co business key la service_id nen cot `hashkey`
cua staging duoc dung truc tiep cho ca 2 nhanh.
Dedup bang row_number theo hashkey, uu tien nguon co priority nho hon.
========================================================================
*/

{% set raw_sql %}
WITH unioned_source AS (
    SELECT
        hashkey AS ocb_bill_services_hashkey,
        service_id AS business_key,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
        CONCAT('{{ source_name }}', '__', 'ocb_bill_services') AS record_source,
        load_timestamp,
        1 AS source_priority
    FROM {{ ref('v_stg_ocbchannel_ocb_bill_services') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND service_id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS ocb_bill_services_hashkey,
        service_id AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'ocb_bill_service_provider') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_ocbchannel_ocb_bill_service_provider') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND service_id IS NOT NULL
),
deduped AS (
    SELECT
        ocb_bill_services_hashkey,
        business_key,
        source_event_date,
        record_source,
        load_timestamp,
        row_number() OVER (
            PARTITION BY ocb_bill_services_hashkey
            ORDER BY source_priority
        ) AS rn
    FROM unioned_source
    WHERE business_key IS NOT NULL
      AND trim(CAST(business_key AS string)) <> ''
)
SELECT
    ocb_bill_services_hashkey,
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
