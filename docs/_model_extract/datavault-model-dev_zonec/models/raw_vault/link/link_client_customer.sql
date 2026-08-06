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
    alias = 'link_client_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_client_customer_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'entity', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 'way4' %}
{% set source_table = 'client' %}
{% set client_business_key_cols = ['ID'] %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(['ID', 'CLIENT_NUMBER'], source_name) }} AS link_client_customer_hashkey,
    {{ hash_column(client_business_key_cols,source_name) }} AS client_hashkey,
    {{ hash_column(['CLIENT_NUMBER'], source_name) }} AS customer_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_way4_client') }}
WHERE source_event_date= to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND amnd_state = 'A'
AND id IS NOT NULL  
AND client_number IS NOT NULL
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

