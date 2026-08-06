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
    alias = 'link_doc_target_acnt_contract',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_doc_target_acnt_contract_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 'way4' %}
{% set source_table = 'doc' %}
{% set source_business_key_cols = ['doc.ID', 'doc.TARGET_CONTRACT'] %}
{% set document_business_key_cols = ['doc.ID'] %}
{% set acnt_contract_business_key_cols = ['doc.TARGET_CONTRACT'] %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(source_business_key_cols, source_name) }} AS link_doc_target_acnt_contract_hashkey,
    {{ hash_column(document_business_key_cols, source_name) }} AS document_hashkey,
    {{ hash_column(acnt_contract_business_key_cols, source_name) }} AS acnt_contract_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT('{{ source_name }}','__','{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_way4_doc') }} doc
JOIN {{ ref('v_stg_way4_acnt_contract') }} a
    ON a.id = doc.target_contract
   AND a.amnd_state = 'A'
WHERE doc.amnd_state = 'A' AND doc.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{% endset %}

-- Main
{{ link(raw_sql = raw_sql) }}

