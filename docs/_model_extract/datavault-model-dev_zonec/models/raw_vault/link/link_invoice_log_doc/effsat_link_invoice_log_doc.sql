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
    alias = 'effsat_link_invoice_log_doc',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_invoice_log_doc_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase2', 'all']
) }}

{% set source_name = 'way4' %}
{% set source_table = 'ows_invoice_log' %}
{% set source_business_key_cols = ['i.id', 'i.doc_id'] %}
{% set link_model = 'link_invoice_log_doc' %}
{% set unique_key = 'link_invoice_log_doc_hashkey' %}

{%- set raw_sql -%}
SELECT DISTINCT
    {{ hash_column(source_business_key_cols, source_name) }} AS link_invoice_log_doc_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_way4_invoice_log') }} i
JOIN {{ ref('v_stg_way4_doc') }} doc
  ON i.doc_id = doc.id
 AND doc.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
WHERE i.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND doc.amnd_state = 'A'
{%- endset %}

{{ effsat(
    unique_key = unique_key,
    link_model = link_model,
    raw_sql = raw_sql
) }}
