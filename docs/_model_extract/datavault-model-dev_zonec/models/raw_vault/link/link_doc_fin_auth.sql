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
skip_matched_step   : true = bo record khong doi → tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<ten_nguon>'] = filter khi run (dbt run --select tag:<ten_nguon>)
================================================================================
*/
{{ config(
    alias = 'link_doc_fin_auth',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_doc_fin_auth_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'transaction', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 'way4' %}
{% set source_table = 'doc' %}
{% set source_business_key_cols = ['fin.ID', 'fin.DOC__PREV__ID'] %}
{% set document_fin_business_key_cols = ['fin.ID'] %}
{% set document_auth_business_key_cols = ['fin.DOC__PREV__ID'] %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(source_business_key_cols, source_name) }} AS link_doc_fin_auth_hashkey,
    {{ hash_column(document_fin_business_key_cols, source_name) }} AS document_fin_hashkey,
    {{ hash_column(document_auth_business_key_cols, source_name) }} AS document_auth_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT('{{ source_name }}','__','{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_way4_doc') }} fin
LEFT JOIN {{ ref('v_stg_way4_doc') }} auth ON fin.doc__prev__id = auth.id
WHERE fin.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND fin.amnd_state = 'A'
AND fin.DOC__PREV__ID IS NOT NULL
AND fin.ID IS NOT NULL
{% endset %}

-- Main
{{ link(raw_sql = raw_sql) }}

