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
    alias = 'link_data_sharing_consent_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_data_sharing_consent_customer_hashkey'],
    skip_matched_step = true,
    tags = ['omni', 'data_sharing_consent', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 'omni' %}
{% set source_table = 'customer_data_sharing_consent' %}
{% set data_sharing_consent_business_key_cols = ['id'] %}


{%- set raw_sql -%}
SELECT
    {{ hash_column(['id', 'cif'], source_name) }} AS link_data_sharing_consent_customer_hashkey,
    {{ hash_column(data_sharing_consent_business_key_cols, source_name) }} AS data_sharing_consent_hashkey,
    {{ hash_column(['cif'], source_name) }} AS customer_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ref('v_stg_omni_customer_data_sharing_consent')}}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd') and cif is not null and id is not null
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

