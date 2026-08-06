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
    alias = 'effsat_link_liability_contract_account_contract',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_liability_contract_account_contract_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase1', 'all']
) }}

{% set source_name = 'way4' %}
{% set source_table = 'acnt_contract' %}
{% set source_business_key_cols = ['ic.ID', 'li.ID'] %}
{% set link_model = 'link_liability_contract_account_contract' %}
{% set unique_key = 'link_liability_contract_account_contract_hashkey' %}

{%- set raw_sql -%}
select
    {{ hash_column(source_business_key_cols, source_name) }} as link_liability_contract_account_contract_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    concat(cast('{{ source_name }}' as string), '__', '{{ source_table }}') as record_source,
    cast(current_timestamp as timestamp) as load_timestamp
from {{ ref('v_stg_way4_acnt_contract') }} ic
join {{ ref('v_stg_way4_acnt_contract') }} li
    on li.id = ic.liab_contract
    AND li.amnd_state = 'A'
    AND li.con_cat = 'A'
    WHERE 1 = 1
    AND ic.amnd_state = 'A'
    AND ic.con_cat = 'A'
    AND ic.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ effsat(
    unique_key = unique_key,
    link_model = link_model,
    raw_sql = raw_sql
) }}

