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
    alias = 'link_od_registration_overdraft_account',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_od_registration_overdraft_account_hashkey'],
    skip_matched_step = true,
    tags = ['omni', 'od_registration', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 'omni' %}
{% set source_table = 'od_registration' %}
{% set od_registration_business_key_cols = ['id'] %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(['id', 'overdraft_account_no'], source_name) }} AS link_od_registration_overdraft_account_hashkey,
    {{ hash_column(od_registration_business_key_cols, source_name) }} AS od_registration_hashkey,
    {{ hash_column(['overdraft_account_no'], source_name) }} AS account_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ref('v_stg_omni_od_registration')}}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND id IS NOT NULL
AND overdraft_account_no IS NOT NULL
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

