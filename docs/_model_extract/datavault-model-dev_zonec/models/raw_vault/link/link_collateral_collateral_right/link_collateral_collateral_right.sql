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
    alias = 'link_collateral_collateral_right',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_collateral_collateral_right_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'collateral', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 't24' %}
{% set source_table = 't24_collateral' %}
{% set collateral_business_key_cols = ['id'] %}

{%- set raw_sql -%}

with hash_col as
(
    select
        id,
        array_join(slice(split(id, '\\.'), 1, 2), '.') as id_2,
        {{ hash_column(['id', 'id_2'], source_name) }} as link_collateral_collateral_right_hashkey,
        {{ hash_column(collateral_business_key_cols,source_name) }} AS collateral_hashkey,
        {{ hash_column(['id_2'], source_name) }} as collateral_right_hashkey,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date
    from {{ ref('v_stg_t24_t24_collateral')  }}
    WHERE id IS NOT NULL
)
SELECT
    link_collateral_collateral_right_hashkey,
    collateral_right_hashkey,
    collateral_hashkey,
    source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM hash_col
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

