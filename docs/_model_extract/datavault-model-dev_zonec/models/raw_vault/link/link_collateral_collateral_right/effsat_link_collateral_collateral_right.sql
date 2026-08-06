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
    alias = 'effsat_link_collateral_collateral_right',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_collateral_collateral_right_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'collateral', 'phase1', 'all']
) }}

{% set source_name = 't24' %}
{% set source_table = 't24_collateral' %}
{% set link_model = 'link_collateral_collateral_right' %}
{% set unique_key = 'link_collateral_collateral_right_hashkey' %}

{%- set raw_sql -%}
select
    {{ hash_column(['id', 'id_2'], source_name) }} as link_collateral_collateral_right_hashkey,
    source_event_date,
    concat(cast('{{ source_name }}' as string), '__', '{{ source_table }}') as record_source,
    cast(current_timestamp as timestamp) as load_timestamp
from (
    select
        id,
        array_join(slice(split(id, '\\.'), 1, 2), '.') as id_2,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date
    from {{ ref('v_stg_t24_t24_collateral') }}
    where id is not null
) t
where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ effsat(
    unique_key = unique_key,
    link_model = link_model,
    raw_sql = raw_sql
) }}

