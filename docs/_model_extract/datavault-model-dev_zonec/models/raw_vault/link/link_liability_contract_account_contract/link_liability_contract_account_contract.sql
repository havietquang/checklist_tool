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
    alias = 'link_liability_contract_account_contract',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_liability_contract_account_contract_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 'way4' %}
{% set source_table = 'acnt_contract' %}
{% set source_business_key_cols = ['ic.ID','li.ID'] %}
{% set liability_contract_business_key_cols = ['li.ID'] %}
{% set account_contract_business_key_cols = ['ic.ID'] %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(source_business_key_cols, source_name) }} AS link_liability_contract_account_contract_hashkey,
    {{ hash_column(liability_contract_business_key_cols, source_name) }} AS liability_contract_hashkey,
    {{ hash_column(account_contract_business_key_cols, source_name) }} AS account_contract_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM {{ ref('v_stg_way4_acnt_contract') }} ic
    JOIN {{ ref('v_stg_way4_acnt_contract') }} li
        ON li.id = ic.liab_contract
    AND li.amnd_state = 'A'
    AND li.con_cat = 'A'
    WHERE 1 = 1
    AND ic.amnd_state='A'
    AND ic.con_cat = 'A'
    AND ic.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')

{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

