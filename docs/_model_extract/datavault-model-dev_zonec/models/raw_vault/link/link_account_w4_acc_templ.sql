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
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<ten_nguon>'] = filter khi run (dbt run --select tag:<ten_nguon>)
================================================================================
*/
{{ config(
    alias = 'link_account_w4_acc_templ',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_account_w4_acc_templ_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'accounting', 'phase2', 'all']
) }}

-- Extraction
{% set source_model = 'v_stg_way4_account' %}
{% set source_name = 'way4' %}
{% set source_table = 'ows_account' %}
{% set unique_key = 'link_account_w4_acc_templ_hashkey' %}
{% set source_business_key_cols = ['a.id', 'a.acc_templ__id'] %}
{% set account_w4_business_key_cols = ['a.id'] %}
{% set acc_templ_business_key_cols = ['a.acc_templ__id'] %}

{% set raw_sql %}
SELECT
    {{ hash_column(source_business_key_cols, source_name) }} AS link_account_w4_acc_templ_hashkey,
    {{ hash_column(account_w4_business_key_cols, source_name) }} AS account_w4_hashkey,
    {{ hash_column(acc_templ_business_key_cols, source_name) }} AS acc_templ_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_way4_account') }} a
JOIN {{ ref('v_stg_way4_acc_templ') }} at
  ON a.acc_templ__id = at.id
 AND at.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
WHERE a.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND at.amnd_state = 'A'
  AND a.id IS NOT NULL
  AND a.acc_templ__id IS NOT NULL
{% endset %}

-------------

--Main part
{{ link(raw_sql = raw_sql) }}

