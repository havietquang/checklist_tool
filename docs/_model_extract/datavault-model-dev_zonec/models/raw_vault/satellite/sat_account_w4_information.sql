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
unique_key          : Khoa dinh danh record (thuong: hub_hashkey + hashdiff)
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['way4'] = filter khi run (dbt run --select tag:way4)
====================================================================
*/

{{ config(
    alias = 'sat_account_w4_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['account_w4_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['way4', 'accounting', 'phase2', 'all']
) }}


/*
========================================================================
SATELLITE MACRO PARAMETERS
========================================================================
  - source_name         : Ten he thong nguon, dung de tao gia tri cho cot `record_source`.
  - source_table        : Ten bang nghiep vu o he thong nguon.
  - hashdiff_col        : Ten cot hashdiff da duoc tinh san o tang staging.
  - hub_hashkey         : Ten khoa hash dung de lien ket ve bang Hub.
  - source_model        : Model staging lam nguon de doc du lieu.
  - list_cols           : Danh sach cac cot nghiep vu duoc luu trong Satellite.
  - raw_sql (optional)  : Cau SQL tu viet trong truong hop logic phuc tap hoac dac biet.
*/

{% set source_name = 'way4' %}
{% set source_table = 'ows_account' %}
{% set hashdiff_col = 'hashdiff_account_w4_information' %}
{% set hub_hashkey = 'account_w4_hashkey' %}
{% set source_model = 'v_stg_way4_account' %}
{% set list_cols = ['code', 'curr', 'acat', 'due_type', 'account_type', 'account_name', 'account_number', 'gl_number', 'acc_templ__id', 'routing_idt', 'is_am_available', 'apply_dt', 'local_version', 'remote_version', 'interest_rate', 'interest_fee_rate', 'ageing_priority', 'main_account', 'alter_account', 'top_account', 'due_account', 'alter_due_account', 'low_lim_account', 'upp_lim_account', 'interest_account', 'acnt_contract__oid', 'total_blocked', 'own_blocked', 'charge_for_open', 'payment_priority'] %}
{% set raw_sql = None %}


/* 
Truong hop khong su dung marco satellite, co the su dung raw_sql nhu ben duoi de 
viet SQL thu cong, sau do truyen vao macro satellite de tao satellite
*/
{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
