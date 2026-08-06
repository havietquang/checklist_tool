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
    alias = 'link_acnt_contract_client',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_acnt_contract_client_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 'way4' %}
{% set source_table = 'acnt_contract' %}
{% set source_business_key_cols = ['ID', 'CLIENT__ID'] %}
{% set acnt_contract_business_key_cols = ['ID'] %}
{% set client_business_key_cols = ['CLIENT__ID'] %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(source_business_key_cols,source_name) }} AS link_acnt_contract_client_hashkey,
    {{ hash_column(acnt_contract_business_key_cols,source_name) }} AS acnt_contract_hashkey,
    {{ hash_column(client_business_key_cols,source_name) }} AS client_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_way4_acnt_contract') }} 
        WHERE AMND_STATE = 'A'
        AND source_event_date= to_date('{{ var("target_date") }}', 'yyyyMMdd')
        AND ID IS NOT NULL
        AND CLIENT__ID IS NOT NULL
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

