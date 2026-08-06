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
    alias = 'link_usage_action_document',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_usage_action_document_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase2', 'all']
) }}

-- Extraction
{% set source_model = 'v_stg_way4_usage_action' %}
{% set source_name = 'way4' %}
{% set source_table = 'ows_usage_action' %}
{% set unique_key = 'link_usage_action_document_hashkey' %}
{% set source_business_key_cols = ['ua.id', 'ua.doc'] %}
{% set usage_action_business_key_cols = ['ua.id'] %}
{% set document_business_key_cols = ['ua.doc'] %}

{% set raw_sql %}
SELECT
    {{ hash_column(source_business_key_cols, source_name) }} AS link_usage_action_document_hashkey,
    {{ hash_column(usage_action_business_key_cols, source_name) }} AS usage_action_hashkey,
    {{ hash_column(document_business_key_cols, source_name) }} AS document_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_way4_usage_action') }} ua
JOIN {{ ref('v_stg_way4_doc') }} doc
  ON ua.doc = doc.id
 AND doc.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
WHERE ua.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND doc.amnd_state = 'A'
  AND ua.id IS NOT NULL
  AND ua.doc IS NOT NULL
{% endset %}

-------------

--Main part
{{ link(raw_sql = raw_sql) }}

