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
    alias = 'link_collateral_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_collateral_customer_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'collateral', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 't24' %}
{% set source_table = 't24_collateral' %}
{% set collateral_business_key_cols = ['id'] %}


{%- set raw_sql -%}
SELECT
    sha2(
        COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(substring(id, 1, instr(id, '.') - 1) AS string))), '')
    , 256) AS link_collateral_customer_hashkey,
    {{ hash_column(collateral_business_key_cols,source_name) }} AS collateral_hashkey,
    sha2(
        COALESCE(UPPER(TRIM(CAST(substring(id, 1, instr(id, '.') - 1) AS string))), '')
    , 256) AS customer_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_t24_t24_collateral') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND id IS NOT NULL
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

