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
    alias = 'pit_customer',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'entity'],
    unique_key = ['customer_hashkey', 'snapshot_date']
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
{% set source_model = 'hub_customer' %}
{% set src_hashkey = 'customer_hashkey' %}
{% set satellites = 
{
    'sat_customer_information' : 'customer_hashkey'
    ,'sat_customer_extra_information' : 'customer_hashkey'
    ,'sat_customer_contact' : 'customer_hashkey'
    ,'sat_customer_classification' : 'customer_hashkey'
    ,'sat_customer_kyc' : 'customer_hashkey'
    ,'sat_customer_financial_statement' :'customer_hashkey'
    ,'sat_cust_package' : 'customer_hashkey'
} 
%}

{{ pit(source_model=source_model
    ,src_hashkey=src_hashkey
    ,satellites=satellites
    ,sts_hub_table='sts_hub_customer'
    ,sts_hub_pk='customer_hashkey'
) }}
