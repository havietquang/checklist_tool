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
    alias = 'sat_soa_ft_batch_details',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['soa_ft_batch_details_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['ocbchannel', 'soa_ft_batch_details', 'zonec']
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
{% set source_table = 'soa_ft_batch_details' %}
{% set hashdiff_col = 'hashdiff_soa_ft_batch_details' %}
{% set hub_hashkey = 'soa_ft_batch_details_hashkey' %}
{% set source_model = 'v_stg_ocbchannel_soa_ft_batch_details' %}
{% set list_cols = ['ma_key', 'item_id', 'item_no', 'serial_no', 'ft_no', 'debit_account', 'credit_account', 'beneficiary_account', 'trans_type', 'amount_input', 'amount', 'currency', 'cif', 'beneficiary_bank_branch_code', 'beneficiary_bank_name', 'fee_amount', 'validate_status', 'validate_code', 'validate_string', 'is_processing', 'time_begin_process', 'date_created', 'item_type', 'err_code', 'err_message', 'branch_code', 't24_trans_type', 'description', 'status', 'trans_no', 'last_access', 'processing_by', 'status_description', 'ft_date', 'beneficiary', 'prev_status', 'last_updated', 'commissioncode', 'comissiontype', 'user_t24_created', 'source', 'source_ref', 'note', 'bc_bank_sort_code', 'account_name_input', 'beneficiary_address', 'profit_cif', 'virtual_account'] %}
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
