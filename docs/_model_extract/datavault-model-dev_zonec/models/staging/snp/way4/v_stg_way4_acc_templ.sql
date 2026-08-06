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
    alias = 'v_stg_way4_acc_templ',
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
{% set source_table = "ows_acc_templ" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_acc_templ_information': ['acc_scheme__oid', 'from_acc_scheme', 'account_type__id', 'f_i', 'pcat', 'acat', 'reference_only', 'code', 'curr', 'account_name', 'fx_type', 'due_type', 'due_period', 'grace_period', 'due_to_work_day', 'repayment_percent', 'min_repayment', 'min_rq_repayment', 'ageing_tariff', 'is_am_available', 'balance_type', 'group_code', 'charge_for_open'],
    'hashdiff_acc_templ_gl': ['gl_credit', 'gl_debit', 'gl_turnover', 'gl_type', 'gl_number', 'hd_gl_number', 'gl_tariff', 'use_gl', 'account_numeration', 'acc_number_counter'],
    'hashdiff_acc_templ_interest': ['interest_scheme', 'interest_algorithm', 'calc_when_credit', 'interest_delay', 'interest_rate', 'interest_fee', 'interest_acc_templ', 'interest_contract', 'int_accrual_acc', 'int_rev_exp_acc', 'int_fee_account', 'interest_fee_type', 'fee_rate_regime', 'interest_tariff', 'last_int_accrual'],
    'hashdiff_acc_templ_limit': ['due_acc_templ', 'alter_due_templ', 'event_type', 'upp_lim_acc_templ', 'low_lim_acc_templ', 'upp_lim_amount', 'low_lim_amount', 'priority', 'ageing_priority', 'offbalance_xf_acc', 'suppl_cr_account', 'suppl_dr_account', 'template_details', 'is_ready'],
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
