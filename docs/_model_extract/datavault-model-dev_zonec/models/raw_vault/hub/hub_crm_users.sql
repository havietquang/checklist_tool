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
tags                : ['crm'] = filter khi run (dbt run --select tag:crm)
====================================================================
*/
{{ config(
    alias = 'hub_crm_users',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['crm_users_hashkey'],
    skip_matched_step = true,
    tags = ['crm', 'contact', 'phase2', 'all', 'zonec']
) }}

{% set source_name = 'crm' %}
{% set unique_key = 'crm_users_hashkey' %}

/*
========================================================================
RAW SQL
========================================================================
Hub duoc nap tu 3 nguon (UNION DISTINCT theo user_id):
  1. crm_users.user_id                    (nguon chinh, priority 1)
  2. crm_user_structure.user_id           (nguon phu,   priority 2)
  3. crm_user_structure.user_manager_id   (nguon phu,   priority 3)
Voi crm_user_structure, cot `hashkey` cua staging la hash cua business
key rieng cua no (user_id) nen phai hash lai user_id/user_manager_id
bang macro hash_column de dam bao hashkey dong nhat voi nguon chinh.
Dedup bang row_number theo hashkey, uu tien nguon co priority nho hon.
========================================================================
*/

{% set raw_sql %}
WITH unioned_source AS (
    SELECT
        hashkey AS crm_users_hashkey,
        user_id AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'crm_users') AS record_source,
        load_timestamp,
        1 AS source_priority
    FROM {{ ref('v_stg_crm_crm_users') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND user_id IS NOT NULL

    UNION ALL

    SELECT
        {{ hash_column(['user_id'], source_name) }} AS crm_users_hashkey,
        user_id AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'crm_user_structure') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_crm_crm_user_structure') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND user_id IS NOT NULL

    UNION ALL

    SELECT
        {{ hash_column(['user_manager_id'], source_name) }} AS crm_users_hashkey,
        user_manager_id AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'crm_user_structure') AS record_source,
        load_timestamp,
        3 AS source_priority
    FROM {{ ref('v_stg_crm_crm_user_structure') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND user_manager_id IS NOT NULL
),
deduped AS (
    SELECT
        crm_users_hashkey,
        business_key,
        source_event_date,
        record_source,
        load_timestamp,
        row_number() OVER (
            PARTITION BY crm_users_hashkey
            ORDER BY source_priority
        ) AS rn
    FROM unioned_source
    WHERE business_key IS NOT NULL
      AND trim(CAST(business_key AS string)) <> ''
)
SELECT
    crm_users_hashkey,
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





