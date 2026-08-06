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
    alias = 'link_crb_loans',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_crb_loans_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'crb', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 't24' %}
{% set source_table = 't24_crb' %}
{% set source_business_key_cols = ['a.tieukhoan', 'a.gl', 'b.id'] %}
{% set customer_business_key_cols = ['a.tieukhoan', 'a.gl'] %}
{% set loans_business_key_cols = ['b.id'] %}

{%- set raw_sql -%}
SELECT DISTINCT
    {{ hash_column(source_business_key_cols,source_name) }} AS link_crb_loans_hashkey,
    {{ hash_column(customer_business_key_cols,source_name) }} AS crb_hashkey,
    {{ hash_column(loans_business_key_cols,source_name) }} AS loans_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_t24_t24_crb') }} a
JOIN {{ ref('v_stg_t24_t24_loans_and_deposits') }} b
    ON a.tieukhoan = b.id
WHERE a.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND b.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND a.tieukhoan LIKE 'LD%'
AND a.tieukhoan IS NOT NULL
AND a.gl IS NOT NULL
AND b.id IS NOT NULL
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}


