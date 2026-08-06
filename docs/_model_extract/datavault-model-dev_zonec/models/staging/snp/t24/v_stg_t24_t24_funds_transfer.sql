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
    alias = 'v_stg_t24_t24_funds_transfer',
    materialized = 'view',
    tags = ['t24', 'transaction', 'phase1', 'all', 'zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_funds_transfer'),
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
{% set source_table = "t24_funds_transfer" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_funds_transfer_account': ['t_acct_with_bank_acc', 't_sub_va_id', 't_in_ben_acct_no', 't_ordering_ac', 't_ben_acct_no', 't_acct_with_bank'],
    'hashdiff_funds_transfer_fee': ['t_commission_type', 't_commission_code', 't_commission_amt', 't_processing_date', 't_classify_code', 't_is_tct', 't_user_type', 't_total_charge_amt', 't_total_tax_amount', 't_charges_acct_no'],
    'hashdiff_funds_transfer_information': ['t_transaction_type', 't_record_status', 't_ocb_cont_value', 't_ocb_tot_val_use', 't_ocb_value_use', 't_ocb_contract_no', 't_online_ref_id', 't_debit_value_date', 't_debit_amount', 't_amount_debited', 't_loc_amt_debited', 't_debit_their_ref', 't_credit_value_date', 't_credit_amount', 't_amount_credited', 't_loc_amt_credited', 't_credit_their_ref', 't_payment_details', 't_debit_currency', 't_credit_currency', 't_clearing_id', 't_debit_acct_no', 't_credit_acct_no'],
    'hashdiff_funds_transfer_other': ['t_ocb_tax_code', 't_ocb_bank_id', 't_ocb_smartlink', 't_ocb_ld_htls', 't_at_auth_code', 't_ocb_term_htls', 't_ocb_ben_acct', 't_ocb_ben_cust', 't_ocb_r_ci_name', 't_ocb_li_cont_id', 't_ocb_contra_ccy', 't_bk_to_bk_out', 't_ben_name', 't_ocb_channel', 't_ocb_billi_code', 't_bc_bank_sort_code', 't_charge_code', 't_sending_addr', 't_msg_narrative', 't_is_prepay', 't_receiving_addr', 't_border_trans', 't_eft_country', 't_in_ordering_bk', 't_in_ben_name', 't_tax_code'],
    'hashdiff_funds_transfer_party': ['t_r_ci_code', 't_bidv_recvrbank', 't_bidv_benbkcode', 't_bidv_senderbank', 't_in_ben_customer', 't_ordering_cust', 't_ben_customer', 't_ben_our_charges', 't_ocb_o_ci_code', 't_ocb_o_ci_name', 't_inw_send_bic', 't_intermed_bank', 't_ben_bank_branch', 't_ordering_bank', 't_cu_d_ord_cpt', 't_profit_centre_cust'],
    'hashdiff_funds_transfer_system': ['t_inputter', 't_authoriser', 't_mkfile_com', 't_message_type', 't_user_input', 't_user_auth', 't_trans_unique_id', 't_stmt_nos', 't_ft_out_purpose', 't_in_swift_msg', 't_date_time'],
    'hashdiff_funds_transfer_detail': ['t_ordering_bank_2', 't_ordering_ac', 't_ocb_cu_d_od_cpt', 't_ocb_intmed_bank', 't_ocb_ac_wth_bank', 't_ocb_bpm_no', 't_treasury_rate'],
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
