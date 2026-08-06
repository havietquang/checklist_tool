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
    alias = 'link_acnt_contract_account_t24',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_acnt_contract_account_t24_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 'way4' %}
{% set source_table = 'acnt_contract' %}
{% set acnt_contract_business_key_cols = ['cc.ID'] %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(['cc.ID', 't24.ID'], source_name) }} AS link_acnt_contract_account_t24_hashkey,
    {{ hash_column(acnt_contract_business_key_cols,source_name) }} AS acnt_contract_hashkey,
    {{ hash_column(['t24.ID'], source_name) }} AS acnt_contract_t24_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM {{ ref('v_stg_way4_acnt_contract') }} cc
    JOIN {{ ref('v_stg_way4_acnt_contract') }} t24 ON t24.acnt_contract__id = cc.id
    AND t24.amnd_state = 'A'
    AND cc.amnd_state = 'A'
    AND cc.data_date = t24.data_date
    AND t24.con_cat = 'C'
    WHERE cc.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')

{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

