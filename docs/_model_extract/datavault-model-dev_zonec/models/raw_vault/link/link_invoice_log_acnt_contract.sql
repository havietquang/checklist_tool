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
    alias = 'link_invoice_log_acnt_contract',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_invoice_log_acnt_contract_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase2', 'all']
) }}

-- Extraction
{% set source_model = 'v_stg_way4_invoice_log' %}
{% set source_name = 'way4' %}
{% set source_table = 'ows_invoice_log' %}
{% set unique_key = 'link_invoice_log_acnt_contract_hashkey' %}
{% set source_business_key_cols = ['i.id', 'i.acnt_contract__oid'] %}
{% set invoice_log_business_key_cols = ['i.id'] %}
{% set acnt_contract_business_key_cols = ['i.acnt_contract__oid'] %}

{% set raw_sql %}
SELECT
    {{ hash_column(source_business_key_cols, source_name) }} AS link_invoice_log_acnt_contract_hashkey,
    {{ hash_column(invoice_log_business_key_cols, source_name) }} AS invoice_log_hashkey,
    {{ hash_column(acnt_contract_business_key_cols, source_name) }} AS acnt_contract_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_way4_invoice_log') }} i
JOIN {{ ref('v_stg_way4_acnt_contract') }} ac
  ON i.acnt_contract__oid = ac.id
 AND ac.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
WHERE i.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND ac.amnd_state = 'A'
  AND i.id IS NOT NULL
  AND i.acnt_contract__oid IS NOT NULL
{% endset %}

-------------

--Main part
{{ link(raw_sql = raw_sql) }}

