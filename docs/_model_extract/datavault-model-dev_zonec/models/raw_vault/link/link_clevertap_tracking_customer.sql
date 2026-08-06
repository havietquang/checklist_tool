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
    alias = 'link_clevertap_tracking_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_clevertap_tracking_customer_hashkey'],
    skip_matched_step = true,
    tags = ['omni', 'clevertap_tracking', 'phase2', 'all']
) }}

{% set source_name = 'omni' %}
{% set source_table = 'clevertap_tracking' %}
{% set clevertap_tracking_business_key_cols = ['id'] %}
{% set customer_business_key_cols = ['cif'] %}

{%- set raw_sql -%}
SELECT
    sha2(
        COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(cif AS string))), '')
    , 256) AS link_clevertap_tracking_customer_hashkey,

    {{ hash_column(clevertap_tracking_business_key_cols, source_name) }} AS clevertap_tracking_hashkey,

    sha2(COALESCE(UPPER(TRIM(CAST(cif AS string))), ''), 256) AS customer_hashkey,

    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_omni_clevertap_tracking') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND id IS NOT NULL
  AND cif IS NOT NULL
{%- endset %}

{{ link(raw_sql = raw_sql) }}
