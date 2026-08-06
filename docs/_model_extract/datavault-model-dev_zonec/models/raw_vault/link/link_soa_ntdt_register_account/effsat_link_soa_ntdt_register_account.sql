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
tags                : ['<ten_nguon>'] = filter khi run (dbt run --select tag:<ten_nguon>)
================================================================================
*/
{{ config(
    alias = 'effsat_link_soa_ntdt_register_account',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_soa_ntdt_register_account_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['ocbchannel', 'soa_ntdt_register', 'zonec']
) }}

{% set source_name = 'ocbchannel' %}
{% set source_table = 'soa_ntdt_register_detail' %}
{% set source_business_key_cols = ['register_id', 'bank_account'] %}
{% set link_model = 'link_soa_ntdt_register_account' %}
{% set unique_key = 'link_soa_ntdt_register_account_hashkey' %}

{%- set raw_sql -%}
SELECT DISTINCT
    {{ hash_column(source_business_key_cols, source_name) }} AS link_soa_ntdt_register_account_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_ocbchannel_soa_ntdt_register_detail') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND register_id IS NOT NULL
  AND bank_account IS NOT NULL
{%- endset %}

{{ effsat(
    unique_key = unique_key,
    link_model = link_model,
    raw_sql = raw_sql
) }}
