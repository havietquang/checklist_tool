/*
================================================================================
DBT CONFIGURATION GUIDE
================================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['omni'] = filter khi run (dbt run --select tag:omni)
================================================================================
*/
{{ config(
    alias = 'link_message_user',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_message_user_hashkey'],
    skip_matched_step = true,
    tags = ['omni', 'message', 'phase2', 'all']
) }}

{% set source_name = 'omni' %}
{% set source_table = 'message' %}
{% set message_business_key_cols = ['id'] %}
{% set user_business_key_cols = ['recipient'] %}

{%- set raw_sql -%}
SELECT
    sha2(
        COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(recipient AS string))), '')
    , 256) AS link_message_user_hashkey,

    {{ hash_column(message_business_key_cols, source_name) }} AS message_hashkey,

    sha2(COALESCE(UPPER(TRIM(CAST(recipient AS string))), ''), 256) AS omni_user_hashkey,

    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_omni_message') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND id IS NOT NULL
  AND recipient IS NOT NULL
{%- endset %}

{{ link(raw_sql = raw_sql) }}
