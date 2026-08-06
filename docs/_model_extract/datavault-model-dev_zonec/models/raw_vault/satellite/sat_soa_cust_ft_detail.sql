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
    alias = 'sat_soa_cust_ft_detail',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['soa_cust_ft_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['ocbchannel', 'soa_cust_ft', 'zonec']
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
{% set source_table = 'soa_cust_ft' %}
{% set hashdiff_col = 'hashdiff_soa_cust_ft_detail' %}
{% set hub_hashkey = 'soa_cust_ft_hashkey' %}
{% set source_model = 'v_stg_ocbchannel_soa_cust_ft' %}
{% set list_cols = ['commission_amount', 'commission_option', 'commission_type', 'exchange_rate', 'tax_amount', 'amount_credited', 'fee_charge_acc', 'discount_fee_type', 'discount_fee_amount', 'credit_card_no', 'credit_card_pay_status', 'credit_card_pay_info', 'credit_card_rev_status', 'credit_card_rev_info', 'credit_card_token_number', 'credit_card_pay_trans_id', 'credit_card_cif', 'credit_card_account', 'credit_card_name', 'trans_type', 'ft_type', 'extra_info', 'ref_type', 'ref_no', 'ref_id', 'branch_code_transfer', 'smartlink_type', 'debit_type', 'debit_account_name', 'debit_account_1', 'classify_code', 'virtual_account', 'virtual_account_name', 'ld_no', 'profit_period', 'is_onegate_trans', 'trans_branch_code', 'is_refund', 'refund_account', 'credit_cif', 'credit_account_name'] %}
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
