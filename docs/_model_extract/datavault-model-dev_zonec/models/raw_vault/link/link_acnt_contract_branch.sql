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
    alias = 'link_acnt_contract_branch',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_acnt_contract_branch_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 'way4' %}
{% set source_table = 'acnt_contract' %}
{% set acnt_contract_business_key_cols = ['ID'] %}

{%- set raw_sql -%}
SELECT
     sha2(
        COALESCE(UPPER(TRIM(CAST(ID AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST('VN001' || BRANCH AS string))), '')
    , 256) AS link_acnt_contract_branch_hashkey,

    {{ hash_column(acnt_contract_business_key_cols, source_name) }} AS acnt_contract_hashkey,

    sha2(
        COALESCE(UPPER(TRIM(CAST('VN001' || BRANCH AS string))), '')
    , 256) AS branch_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_way4_acnt_contract') }}
WHERE AMND_STATE = 'A'
  AND source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND ID IS NOT NULL
  AND BRANCH IS NOT NULL
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

