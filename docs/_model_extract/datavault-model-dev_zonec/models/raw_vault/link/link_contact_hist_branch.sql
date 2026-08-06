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
    alias = 'link_contact_hist_branch',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_contact_hist_branch_hashkey'],
    skip_matched_step = true,
    tags = ['crm', 'contact', 'phase2', 'all']
) }}

-- Extraction
{% set source_name = 'crm' %}
{% set source_table = 'crm_contact_hist' %}
{% set contact_hist_business_key_cols = ['id'] %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(['id', 'branch_code'], source_name) }} AS link_contact_hist_branch_hashkey,
    {{ hash_column(contact_hist_business_key_cols,source_name) }} AS crm_contact_hist_hashkey,
    {{ hash_column(['branch_code'], source_name) }} AS branch_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_crm_crm_contact_hist') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND id IS NOT NULL
AND branch_code IS NOT NULL
{%- endset %}
-------------
--Main part
{{ link(raw_sql = raw_sql) }}

