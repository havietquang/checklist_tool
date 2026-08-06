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
    alias = 'link_transfer_bill_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_transfer_bill_customer_hashkey'],
    skip_matched_step = true,
    tags = ['omni', 'transfer_bill', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 'omni' %}
{% set transfer_bill_business_key_cols = ['id'] %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(['id', 'cif'], source_name) }} AS link_transfer_bill_customer_hashkey,
    {{ hash_column(transfer_bill_business_key_cols, source_name) }} AS transfer_bill_hashkey,
    {{ hash_column(['cif'], source_name) }} AS customer_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('omni' AS string), '__', 'transfer_bill_history') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ref('v_stg_omni_transfer_bill_history')}}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd') AND id IS NOT NULL AND cif IS NOT NULL
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

