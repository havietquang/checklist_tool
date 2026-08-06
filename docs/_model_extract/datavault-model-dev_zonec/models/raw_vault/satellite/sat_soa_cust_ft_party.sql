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
    alias = 'sat_soa_cust_ft_party',
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
{% set hashdiff_col = 'hashdiff_soa_cust_ft_party' %}
{% set hub_hashkey = 'soa_cust_ft_hashkey' %}
{% set source_model = 'v_stg_ocbchannel_soa_cust_ft' %}
{% set list_cols = ['cust_id_no', 'cust_id_date', 'cust_id_place', 'cust_id_type', 'cust_type', 'cust_address', 'cust_taxcode', 'cust_name', 'cust_phone_no', 'cif_advance', 'cif_deposit', 'fee_charge_cif', 'user_created_t24', 'beneficiary', 'beneficiary_id_no', 'beneficiary_id_date', 'beneficiary_id_place', 'beneficiary_account', 'beneficiary_currency', 'beneficiary_bank', 'beneficiary_bank_branch', 'beneficiary_address', 'bc_bank_sort_code', 'beneficiary_phone', 'adhoc_beneficiary'] %}
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
