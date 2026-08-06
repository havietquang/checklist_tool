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
    alias = 'link_acnt_contract_product',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_acnt_contract_product_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'product', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 'way4' %}
{% set source_table = 'acnt_contract' %}
{% set source_business_key_cols = ['ac.ID', 'ap.id'] %}
{% set acnt_contract_business_key_cols = ['ac.ID'] %}
{% set product_business_key_cols = ['ap.id'] %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(source_business_key_cols, source_name) }} AS link_acnt_contract_product_hashkey,
    {{ hash_column(acnt_contract_business_key_cols, source_name) }} AS acnt_contract_hashkey,
    {{ hash_column(product_business_key_cols, source_name) }} AS product_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT('{{ source_name }}','__','{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM  {{ ref('v_stg_way4_acnt_contract') }} ac
    JOIN {{ ref('v_stg_way4_appl_product') }} ap 
    ON ac.product = ap.internal_code
    WHERE ac.AMND_STATE = 'A' AND ap.AMND_STATE = 'A' AND ac.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}


