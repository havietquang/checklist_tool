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
unique_key          : Khoa dinh danh record (hub_hashkey + ma_key + hashdiff)
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['ocbchannel'] = filter khi run (dbt run --select tag:ocbchannel)
====================================================================
*/

{{ config(
    alias = 'sat_apportion_trans_batch_details',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['apportion_trans_batch_details_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['ocbchannel', 'apportion_trans_batch_details', 'zonec']
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
                          Co 'ma_key' -> macro tu bat logic multi-active.
  - raw_sql (optional)  : Cau SQL tu viet trong truong hop logic phuc tap hoac dac biet.
========================================================================
*/

{% set source_name = 'ocbchannel' %}
{% set source_table = 'apportion_trans_batch_details' %}
{% set hashdiff_col = 'hashdiff_apportion_trans_batch_details' %}
{% set hub_hashkey = 'apportion_trans_batch_details_hashkey' %}
{% set source_model = 'v_stg_ocbchannel_apportion_trans_batch_details' %}
{% set list_cols = ['ma_key', 'item_id', 'serial_no', 'cust_name', 'branch_code', 'tax', 'vat_form', 'vat_inv_code', 'vat_inv_serial', 'vat_inv_date', 'vat_inv_goods', 'vat_rate', 'debit_account', 'debit_currency', 'credit_account', 'credit_currency', 'amount', 'description', 'note', 'department_id', 'date_created', 'user_created', 'trans_type', 'status_trans', 'status', 'validate_status', 'validate_text', 'is_processing', 'processing_by', 'prev_status', 'last_access', 'ft_no', 'status_description', 'vat_type'] %}
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
