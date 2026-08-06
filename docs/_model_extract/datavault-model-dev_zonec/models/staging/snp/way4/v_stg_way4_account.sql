/*
========================================================================
DBT CONFIGURATION GUIDE
========================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias        : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['way4'] = filter khi run (dbt run --select tag:way4)
========================================================================
*/

{{ config(
    alias = 'v_stg_way4_account',
    materialized = 'view',
    tags = ['way4', 'accounting', 'phase2', 'all']
) }}


/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('way4'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon, dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat cua entity.
  - source_event_date_col : Cot ngay su kien tu nguon, dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach cot tuong ung.
========================================================================
*/

{% set source_name = "way4" -%}
{% set source_table = "ows_account" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_account_w4_information': ['code', 'curr', 'acat', 'due_type', 'account_type', 'account_name', 'account_number', 'gl_number', 'acc_templ__id', 'routing_idt', 'is_am_available', 'apply_dt', 'local_version', 'remote_version', 'interest_rate', 'interest_fee_rate', 'ageing_priority', 'main_account', 'alter_account', 'top_account', 'due_account', 'alter_due_account', 'low_lim_account', 'upp_lim_account', 'interest_account', 'acnt_contract__oid', 'total_blocked', 'own_blocked', 'charge_for_open', 'payment_priority'],
    'hashdiff_account_w4_balance': ['begin_balance', 'current_balance', 'low_lim_amount', 'upp_lim_amount', 'on_date_balance', 'on_date', 'cycle_date_from', 'cycle_date_to', 'n_of_cycle'],
} -%}


/*
------------------------------------------------------------------------
STAGE MACRO CALL
------------------------------------------------------------------------
Guard `if execute` ngan macro chay luc dbt parse/compile
(tranh loi khi chua co context thuc thi).
Macro `stage()` se sinh ra cau SELECT day du gom:
  - Tat ca cot goc tu source
  - Cot hashkey (hash cua business_key_cols)
  - Cac cot hashdiff theo hashdiff_satellite_dict
  - Cot record_source, source_event_date, load_timestamp
------------------------------------------------------------------------
*/

{% if execute -%}
{{ stage(source_table=source_table
        ,business_key_cols=business_key_cols
        ,hashdiff_satellite_dict=hashdiff_satellite_dict
        ,source_event_date_col=source_event_date_col
        ,source_event_date_dttype=source_event_date_dttype
        ,source_name=source_name)
}}
{% endif -%}
