/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/

{{ config(
    alias = 'v_stg_t24_t24_diary',
    materialized = 'view',
    tags = ['t24', 'security', 'phase2', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_diary'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('data_date'),
                            dung lam source_event_date o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name = 't24' -%}
{% set source_table = "t24_diary" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_diary_information': ['t_security_no', 't_narrative', 't_event_type', 't_depository', 't_ex_date', 't_pay_date', 't_value_date', 't_currency', 't_rate_type', 't_option_desc', 't_rate', 't_percentage', 't_commission_code', 't_net_charges', 't_bond_share_flag', 't_dep_no', 't_dep_type', 't_dep_account_no', 't_total_cash', 't_total_cash_ccy', 't_total_cash_xch', 't_total_cash_lccy', 't_rp_tot_cash', 't_rp_tot_cash_lcy', 't_tot_security', 't_option', 't_accrual_start_date', 't_portfolio_no', 't_cash_hold_settle', 't_sec_hold_settle', 't_total_credit'],
    'hashdiff_diary_system': ['t_vault_update', 't_local_tax_perc', 't_total_debit', 't_option_nominal', 't_option1', 't_opt1_depot', 't_opt1_nominal', 't_opt1_cash', 't_opt1_cash_ccy', 't_opt1_sec', 't_opt1_debit', 't_auto_update', 't_source', 't_cash_hold_settle', 't_sec_hold_settle', 't_total_credit'],
}
-%}

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
        ,source_name=source_name
         )
}}
{% endif -%}
