/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record cua PIT
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<source_name>'] = filter khi run (dbt run --select tag:<source_name>)
====================================================================
*/
{{ config(
    alias = 'pit_acnt_contract',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['way4', 'contract'],
    unique_key = ['acnt_contract_hashkey', 'snapshot_date']
) }}

/*
========================================================================
PIT MACRO PARAMETERS
========================================================================
  - source_model : Ten bang Hub nguon trong raw_vault lam tap record goc.
  - src_hashkey  : Hashkey cua Hub nguon.
  - satellites   : Mapping giua bang Satellite va cot hashkey dung de join.
========================================================================
*/
{% set source_model = 'hub_acnt_contract' %}
{% set src_hashkey = 'acnt_contract_hashkey' %}
{% set satellites = 
{
    'sat_acnt_contract_cs_status_log' : 'acnt_contract_hashkey'
    ,'sat_acnt_contract_information' : 'acnt_contract_hashkey'
    ,'sat_acnt_contract_other' : 'acnt_contract_hashkey'
    ,'sat_acnt_contract_add_data' : 'acnt_contract_hashkey'
    ,'sat_acnt_contract_type' : 'acnt_contract_hashkey'
} 
%}

{{ pit(source_model=source_model
    ,src_hashkey=src_hashkey
    ,satellites=satellites
) }}
