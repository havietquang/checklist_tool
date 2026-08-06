/*
========================================================================
DBT CONFIGURATION GUIDE
========================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['way4'] = filter khi run (dbt run --select tag:way4)
========================================================================
*/

{{ config(
    alias = 'v_stg_way4_templ_approved',
    materialized = 'view',
    tags = ['way4', 'accounting', 'phase2', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('way4'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('ows_templ_approved'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('date_from'),
                            dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name  = "way4" -%}
{% set source_table = "ows_templ_approved" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_templ_approved_information': ['account_type', 'account_name', 'group_code', 'curr', 'acat', 'f_i', 'fx_type', 'event_type', 'template_details', 'date_from', 'date_to', 'is_active', 'officer', 'acc_scheme__id', 'code', 'acc_templ__oid', 'account_numeration'],
    'hashdiff_templ_approved_repayment': ['due_acc_templ','alt_due_templ','due_type','due_period','grace_period','due_to_work_day','min_repayment','min_rq_repayment','repayment_percent','ageing_tariff','ageing_priority'],
    'hashdiff_templ_approved_interest': [ 'interest_scheme', 'interest_algorithm', 'interest_rate', 'interest_tariff', 'interest_fee', 'interest_fee_type','charge_for_open','fee_rate_regime','interest_delay','calc_when_credit'],
    'hashdiff_templ_approved_gl': ['gl_type','gl_number','hd_gl_number','gl_tariff','interest_acc_templ','int_accrual_acc','int_fee_account','int_rev_exp_acc','offbalance_xf_acc','suppl_cr_account','suppl_dr_account','use_gl'],
    'hashdiff_templ_approved_limit': ['balance_type','upp_lim_amount','low_lim_amount','upp_lim_acc_templ','low_lim_acc_templ','priority','is_am_available'],
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
