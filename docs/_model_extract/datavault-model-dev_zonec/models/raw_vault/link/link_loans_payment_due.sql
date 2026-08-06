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
    alias = 'link_loans_payment_due',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_loans_payment_due_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'loan', 'phase1', 'all', 'bv_zonec']
) }}

-- Extraction
{% set source_name = 't24' %}
{% set source_table = 't24_payment_due' %}
{% set loans_payment_due_business_key_cols = ['id'] %}

{%- set raw_sql -%}

with hash_col as (
    select
        id,
        substring(id, 3) as id_loans,
        {{ hash_column(loans_payment_due_business_key_cols, source_name) }} AS loans_payment_due_hashkey,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date
    from {{ ref('v_stg_t24_t24_payment_due') }}
)
SELECT
    {{ hash_column(['id', 'id_loans'], source_name) }} AS link_loans_payment_due_hashkey,
    loans_payment_due_hashkey,
    {{ hash_column(['id_loans'], source_name) }} AS loans_hashkey,
    source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM hash_col
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND id IS NOT NULL
AND id_loans IS NOT NULL
AND ID LIKE 'PDLD%'
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

