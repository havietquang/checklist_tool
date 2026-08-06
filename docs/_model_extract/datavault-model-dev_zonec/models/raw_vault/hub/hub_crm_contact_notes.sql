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
    alias = 'hub_crm_contact_notes',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['crm_contact_notes_hashkey'],
    skip_matched_step = true,
    tags = ['crm', 'contact', 'phase2', 'all']
) }}

{% set raw_sql %}
SELECT
    crm_contact_notes_hashkey,
    business_key,
    source_event_date,
    record_source,
    load_timestamp
FROM (
    SELECT
        {{ hash_column(['id'], 'crm') }} AS crm_contact_notes_hashkey,
        CAST(id AS STRING) AS business_key,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
        CONCAT('crm', '__', 'crm_contact_notes') AS record_source,
        CURRENT_TIMESTAMP AS load_timestamp,
        1 AS source_priority
    FROM {{ ref('v_stg_crm_crm_contact_notes') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
    AND id IS NOT NULL

    UNION ALL

    SELECT DISTINCT
        {{ hash_column(['contactnoteid'], 'crm') }} AS crm_contact_notes_hashkey,
        CAST(contactnoteid AS STRING) AS business_key,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
        CONCAT('crm', '__', 'crm_contact_hist') AS record_source,
        CURRENT_TIMESTAMP AS load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_crm_crm_contact_hist') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
    AND contactnoteid IS NOT NULL
)
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY crm_contact_notes_hashkey
    ORDER BY source_priority
) = 1
{% endset %}

{{ hub(raw_sql=raw_sql) }}





