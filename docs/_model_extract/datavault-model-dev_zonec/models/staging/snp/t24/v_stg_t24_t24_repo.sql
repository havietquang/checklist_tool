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
    alias = 'v_stg_t24_t24_repo',
    materialized = 'view',
    tags = ['t24', 'repo', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_repo'),
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
{% set source_table = "t24_repo" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_repo_classification': ['repo_type', 'product_category', 'deal_type', 'agreement_type', 'broker_no'],
    'hashdiff_repo_deal': ['currency', 'principal_amount_1', 'principal_amount_2', 'new_nominal', 'repo_rate', 'repo_interest', 'dirty_price', 't_clean_price', 't_gross_amount', 't_gross_amt_sec', 'accrued_int_amt', 'ocb_order_date', 'send_payment', 't_mm_locref_name', 'drawdown_account', 'prin_liq_acct', 'int_liq_acct', 'new_cu_acct_no', 'margin_portfolio', 'total_settlemnt','new_sec_code'],
    'hashdiff_repo_information': ['contract_status', 'trade_date', 'value_date', 'maturity_date', 't_st_contract_id', 'inputter', 'authoriser', 't_record_status', 't_curr_no', 'interest_basis', 'trans_type', 'currency', 'mm_contract_id', 'bank_portfolio', 'limit_reference'],
    'hashdiff_repo_system': ['new_depo', 'business_centre', 'fwd_settlemnt', 'fwd_price', 'fx_rate', 'new_cu_acct_ccy', 'capitalisation'],
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
