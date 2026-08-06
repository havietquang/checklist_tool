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
    alias = 'link_onboarding_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_onboarding_customer_hashkey'],
    skip_matched_step = true,
    tags = ['omni', 'onboarding_report', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 'omni' %}
{% set source_table = 'onboarding_report' %}
{% set onboarding_business_key_cols = ['case_key'] %}


{%- set raw_sql -%}
SELECT
    {{ hash_column(['case_key', 'cif'], source_name) }} AS link_onboarding_customer_hashkey,
    {{ hash_column(onboarding_business_key_cols, source_name) }} AS onboarding_hashkey,
    {{ hash_column(['cif'], source_name) }} AS customer_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ref('v_stg_omni_onboarding_report')}}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND case_key IS NOT NULL
AND cif IS NOT NULL
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

