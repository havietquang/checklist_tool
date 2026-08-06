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
    alias = 'link_credit_card_registration_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_credit_card_registration_customer_hashkey'],
    skip_matched_step = true,
    tags = ['omni', 'cc_registration', 'phase1', 'all']
) }}

-- Sources participating: CREDIT_CARD_REGISTRATION
{% set source_name = 'omni' %}
{% set source_business_key_cols = ['ID', 'CIF'] %}
{% set credit_card_registration_business_key_cols = ['ID'] %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(source_business_key_cols,source_name) }} AS link_credit_card_registration_customer_hashkey,
    {{ hash_column(credit_card_registration_business_key_cols,source_name) }} AS credit_card_registration_hashkey,
    {{ hash_column(['CIF'], source_name) }} AS customer_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    'omni__credit_card_registration' AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ref('v_stg_omni_credit_card_registration')}}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND ID IS NOT NULL  
AND CIF IS NOT NULL 
{%- endset %}

{{ link(raw_sql = raw_sql) }}

