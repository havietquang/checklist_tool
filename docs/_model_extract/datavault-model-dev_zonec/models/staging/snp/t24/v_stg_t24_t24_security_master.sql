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
    alias = 'v_stg_t24_t24_security_master',
    materialized = 'view',
    tags = ['t24', 'security', 'phase2', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_security_master'),
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
{% set source_table = "t24_security_master" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_security_classification': ['t_bond_or_share', 't_quoted_listed_no', 't_sub_asset_type', 't_industry_code', 't_industry_levo', 't_industry_lev1', 't_industry_lev2', 't_industry_lev3', 't_industry_levt', 't_ocb_ftp_bd_type', 't_ocb_ftp_callput', 't_bond_type_code', 't_bond_group_code', 't_ftp_fee_repaid', 't_ocb_ftp_vlpaper', 't_ocb_ftp_cifcoll'],
    'hashdiff_security_information': ['t_company_name', 't_descript', 't_short_name', 't_mnemonic', 't_stock_exchange', 't_issue_date', 't_maturity_date', 't_alt_security_id', 't_alt_security_no','t_company_domicile', 't_set_up_date', 't_group_partner', 't_business_pp', 't_bss_detail_pp', 't_sc_ind_internal', 't_trading_units', 't_margin_control', 't_ftp_description', 't_limit_ref'],
    'hashdiff_security_pricing': ['t_last_price', 't_date_last_price', 't_price_currency', 't_price_type', 't_stk_exch_price', 't_par_value', 't_security_currency'],
    'hashdiff_security_terms': ['t_interest_rate', 't_coupon_method', 't_interest_day_basis', 't_no_of_payments', 't_accrual_start_date', 't_add_issue_date', 't_rate_ch_date', 't_ocbint_chg_date', 't_ftp_nd_term_int', 't_bond_int_rate', 't_ftp_int_rate_tp', 't_int_payment_date', 't_income_date', 't_ocb_ftp_frdate', 't_ocb_ftp_tright'],
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
