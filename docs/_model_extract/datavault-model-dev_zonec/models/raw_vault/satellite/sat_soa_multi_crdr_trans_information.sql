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
tags                : ['ocbchannel'] = filter khi run (dbt run --select tag:ocbchannel)
====================================================================
*/

{{ config(
    alias = 'sat_soa_multi_crdr_trans_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['soa_multi_crdr_trans_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['ocbchannel', 'soa_multi_crdr_trans', 'zonec']
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
========================================================================
*/

{% set source_name = 'ocbchannel' %}
{% set source_table = 'soa_multi_crdr_trans' %}
{% set hashdiff_col = 'hashdiff_soa_multi_crdr_trans_information' %}
{% set hub_hashkey = 'soa_multi_crdr_trans_hashkey' %}
{% set source_model = 'v_stg_ocbchannel_soa_multi_crdr_trans' %}
{% set list_cols = ['tt_no', 'serial_no', 'debit_account_1', 'debit_account_2', 'debit_account_3', 'debit_account_4', 'credit_account_1', 'credit_account_2', 'credit_account_3', 'credit_account_4', 'debit_amount_1', 'debit_amount_2', 'debit_amount_3', 'debit_amount_4', 'credit_amount_1', 'credit_amount_2', 'credit_amount_3', 'credit_amount_4', 'payment_details', 'trans_date', 'datetime_created', 'cif', 'trans_type', 'status', 'err_message', 'last_updated', 'prev_status', 'channel', 'currency', 'user_created', 'user_approved', 'processing_by', 'branchid'] %}
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
