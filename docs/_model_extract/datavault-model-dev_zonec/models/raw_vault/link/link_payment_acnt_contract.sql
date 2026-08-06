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
    alias = 'link_payment_acnt_contract',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_payment_acnt_contract_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 'way4' %}
{% set source_table = 'oms_payment' %}
{% set source_business_key_cols = ['p.id', 'p.acnt_contract_id'] %}
{% set payment_business_key_cols = ['p.id'] %}
{% set acnt_contract_business_key_cols = ['p.acnt_contract_id'] %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(source_business_key_cols,source_name) }} AS link_payment_acnt_contract_hashkey,
    {{ hash_column(payment_business_key_cols,source_name) }} AS payment_hashkey,
    {{ hash_column(acnt_contract_business_key_cols,source_name) }} AS acnt_contract_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_way4_payment') }} p
JOIN {{ ref('v_stg_way4_acnt_contract') }} ac ON p.acnt_contract_id = ac.id
AND ac.AMND_STATE = 'A'
WHERE p.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')



{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

