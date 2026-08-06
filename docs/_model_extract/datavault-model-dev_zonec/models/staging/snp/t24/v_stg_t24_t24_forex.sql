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
    alias = 'v_stg_t24_t24_forex',
    materialized = 'view',
    tags = ['t24', 'forex', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_forex'),
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
{% set source_table = "t24_forex" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_forex_classification': ['t_deal_type', 't_fx_type', 't_category', 't_buyfcy_pp', 't_deal_market', 't_our_account_pay', 't_our_account_rec', 't_co_code_inp'],
    'hashdiff_forex_information': ['t_deal_date', 't_value_date_buy', 't_value_date_sell', 't_currency_bought', 't_currency_sold', 't_base_ccy', 't_amount_bought', 't_amount_sold', 't_spot_lcy_amount', 't_buy_lcy_equiv', 't_sel_lcy_equiv', 't_swap_base_ccy', 't_limit_reference_no', 't_swap_ref_no'],
    'hashdiff_forex_other': ['t_bk_to_bk_inf'],
    'hashdiff_forex_rate': ['t_exch_rate', 't_forward_rate', 't_spot_rate'],
    'hashdiff_forex_pricing_pnl': ['t_ho_price', 't_ho_crss_sell1', 't_cu_crss_sell1', 't_cu_crss_sell2', 't_branch_pnl'],
    'hashdiff_forex_payment_swift': ['t_r_ci_code', 't_ibps_bene', 't_receiving_addr', 't_ben_acct_no', 't_cpy_corr_add', 't_cparty_bank_acc', 't_cparty_corr_no', 't_send_confirmation', 't_send_payment', 't_send_advice', 't_ocb_is_tag57a', 't_address', 't_transaction_ref_no', 't_trans_code', 't_mkfile_com'],
    'hashdiff_forex_audit_status': ['t_status', 't_record_status', 't_dealer_desk', 't_group_partner', 't_inputter', 't_authoriser', 't_date_time', 't_curr_no', 't_pst_immdt', 't_override', 't_dealer_notes', 't_notes', 't_contact_name', 't_national_id'],
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
