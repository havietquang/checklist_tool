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
    alias = 'link_collateral_right_limit',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_collateral_right_limit_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'collateral', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 't24' %}
{% set source_table = 't24_collateral_right' %}
{% set collateral_right_business_key_cols = ['id'] %}

{%- set raw_sql -%}
WITH HASH_VALUE AS
(
    SELECT distinct
        id,
        {{ hash_column(collateral_right_business_key_cols,source_name) }} AS collateral_right_hashkey,
        explode(split(t_limit_reference, "::")) as t_limit_reference,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date
    FROM {{ ref('v_stg_t24_t24_collateral_right')  }}

)
SELECT
    {{ hash_column(['id', 't_limit_reference'], source_name) }} AS link_collateral_right_limit_hashkey,
    collateral_right_hashkey,
    {{ hash_column(['t_limit_reference'], source_name) }} AS limit_hashkey,
    source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM HASH_VALUE
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND id IS NOT NULL
AND t_limit_reference IS NOT NULL
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

