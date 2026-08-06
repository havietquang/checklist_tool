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
    alias = 'pit_loan',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'loan'],
    unique_key = ['loans_hashkey', 'snapshot_date']
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
{% set source_model = 'hub_loans' %}
{% set src_hashkey = 'loans_hashkey' %}
{% set satellites = 
{
    'sat_loans_information' : 'loans_hashkey'
    ,'sat_loans_classification' : 'loans_hashkey'
    ,'sat_loans_rate' : 'loans_hashkey'
    ,'sat_loans_terms' : 'loans_hashkey'
} 
%}

{{ pit(source_model=source_model
    ,src_hashkey=src_hashkey
    ,satellites=satellites
    ,sts_hub_table='sts_hub_loans'
    ,sts_hub_pk='loans_hashkey'
) }}
