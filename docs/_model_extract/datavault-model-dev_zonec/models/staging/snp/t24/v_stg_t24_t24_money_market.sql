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
    alias = 'v_stg_t24_t24_money_market',
    materialized = 'view',
    tags = ['t24', 'money_market', 'phase1', 'all', 'bv_zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_money_market'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('data_date'),
                            dung de gan moc thoi gian su kien cho ban ghi.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name = 't24' -%}
{% set source_table = "t24_money_market" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_money_market_classification': ['t_category', 't_mm_type', 't_limit_reference', 't_prin_liq_acct', 't_ben_acct_no', 't_int_liq_acct', 't_co_code_inp', 't_benef_prin_acct', 't_drawdown_account'],
    'hashdiff_money_market_information': ['t_deal_date', 't_value_date', 't_term', 't_maturity_date', 't_principal', 't_currency', 't_orig_start_date', 't_mis_acct_officer', 't_contract_no','t_linked_contract'],
    'hashdiff_money_market_rate': ['t_interest_rate', 't_int_rate_type', 't_interest_basis', 't_interest_spread_1', 't_ocb_intratetype', 't_interest_key'],
    'hashdiff_money_market_rollover_schedule': ['t_rollover_marker', 't_new_interest_rate', 't_rollover_date', 't_capitalisation', 't_prin_increase', 't_incr_eff_date', 't_tot_interest_amt', 't_next_prin_amount', 't_next_int_amount', 't_int_period_start', 't_int_period_end', 't_int_schedule'],
    'hashdiff_money_market_payment_information': ['t_prin_ben_bank_1', 't_prin_ben_bank_2', 't_int_ben_bank_1', 't_int_ben_bank_2', 't_send_payment', 't_trans_code', 't_mkfile_com', 't_r_ci_code', 't_ibps_bene', 't_receiving_addr', 't_prin_address', 't_int_address', 't_our_remarks'],
    'hashdiff_money_market_guarantee': ['t_md_limit_avail', 't_is_guarantee', 't_mm_gua_org', 't_mm_gua_amt', 't_gua_mat_date', 't_gua_type', 't_clr_bal_sheet', 't_cr_derivative', 't_drvt_prod_amt', 't_drvt_p_mat_date', 't_link_reference', 't_md_ref'],
    'hashdiff_money_market_audit_status': ['t_status', 't_record_status', 't_override', 't_inputter', 't_authoriser', 't_date_time', 't_curr_no', 't_dept_code', 't_activity_code', 't_dealer_desk'],
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
