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
    alias = 'effsat_link_account_contract_card',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_account_contract_card_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
   tags = ['way4', 'contract', 'phase1', 'all']
) }}

/*
================================================================================
EFFSAT MACRO PARAMETERS
================================================================================
  - Theo doi snapshot quan he cua Link theo kieu SCD Type 2.
  - Ban ghi dang con hieu luc:
      + active_flag = 1
      + source_event_date = ngay snapshot record con active
  - Ban ghi het hieu luc:
      + active_flag = 0
      + source_event_date = ngay snapshot record bi dong/thay doi/xoa
================================================================================
*/

/* Khai bao bien giong ben link, chi them 1 bien link_model cho effsat. */
{% set source_name = 'way4' %}
{% set source_table = 'acnt_contract' %}
{% set source_business_key_cols = ['ic.ID', 'cc.ID'] %}
{% set account_contract_business_key_cols = ['ic.ID'] %}
{% set card_business_key_cols = ['cc.ID'] %}
{% set link_model = 'link_account_contract_card' %}
{% set unique_key = 'link_account_contract_card_hashkey' %}

{%- set raw_sql -%}
select
    {{ hash_column(source_business_key_cols,source_name) }} as link_account_contract_card_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    concat(cast('way4' as string), '__', 'acnt_contract') as record_source,
    cast(current_timestamp as timestamp) as load_timestamp
from {{ ref('v_stg_way4_acnt_contract') }} ic
join {{ ref('v_stg_way4_acnt_contract') }} cc
        ON ic.id=cc.acnt_contract__oid 
    AND cc.amnd_state='A' 
    WHERE 1 = 1
    AND ic.amnd_state='A'
    AND ic.con_cat = 'A'
    AND ic.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ effsat(
    unique_key = unique_key,
    link_model = link_model,
    raw_sql = raw_sql
) }}
