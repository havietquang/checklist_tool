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
    alias = 'v_stg_t24_t24_sec_trade',
    materialized = 'view',
    tags = ['t24', 'security', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_sec_trade'),
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
{% set source_table = "t24_sec_trade" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_sec_trade_amounts': ['security_currency', 'ocb_yield', 'cu_gross_am_sec', 'cust_intr_amt', 'exch_rate_sec', 'exch_rate_trd', 'cust_price', 'cust_tot_nom', 'cu_gross_accr', 'cu_gross_am_trd', 'ocb_int_basic', 't_cu_net_am_trd', 't_cu_ex_rate_ref', 't_cu_amount_due', 't_ocb_par_value', 'interest_rate', 'cust_no_nom'],
    'hashdiff_sec_trade_broker': ['t_broker_no', 't_broker_type', 't_br_acc_no', 't_br_gross_accr', 't_br_gross_am_sec', 't_br_gross_am_trd', 't_br_intr_am_trd', 't_br_no_nom', 't_br_price', 't_br_tot_nom', 't_br_trans_code'],
    'hashdiff_sec_trade_information': ['price_type', 'depository', 'trade_date', 'value_date', 'market_type', 'cust_trans_code', 'ocb_order_date', 'cust_nominee', 'cust_remarks', 'cust_act_susp_cat', 't_contract_no', 't_index_contract', 'ocb_altsin', 'stock_exchange', 'issue_date', 'maturity_date', 'cust_sec_acc', 'cust_acc_no', 't_cpty_limit_ref', 't_cu_account_ccy', 't_cust_acc_no', 't_value_date_2', 'trade_ccy'],
    'hashdiff_sec_trade_system': ['net_trade', 'last_paymnt_date', 'interest_days', 'inputter', 'authoriser', 'date_time', 't_record_status'],
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
