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
    alias = 'sat_usage_action_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['usage_action_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase2', 'all']
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
{% set source_table = 'ows_usage_action' %}
{% set hashdiff_col = 'hashdiff_usage_action_information' %}
{% set hub_hashkey = 'usage_action_hashkey' %}
{% set source_model = 'v_stg_way4_usage_action' %}
{% set list_cols = ['event_type', 'event_type_next', 'con_cat', 'group_code', 'custom_event_code', 'event_details', 'base_amount', 'base_curr', 'fee_type', 'posting_status', 'cl_stop_list', 'client_stop_list', 'next_action', 'switch_tag', 'standing_order__id', 'usage_limiter__id', 'usage_action__oid', 'process_log__id', 'target_doc', 'partition_key', 'acnt_contract__id', 'doc'] %}
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
