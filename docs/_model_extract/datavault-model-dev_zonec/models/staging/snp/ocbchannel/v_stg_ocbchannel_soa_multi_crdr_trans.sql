/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['ocbchannel'] = filter khi run (dbt run --select tag:ocbchannel)
====================================================================
*/

{{ config(
    alias = 'v_stg_ocbchannel_soa_multi_crdr_trans',
    materialized = 'view',
    tags = ['ocbchannel', 'soa_multi_crdr_trans', 'zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('ocbchannel'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('soa_multi_crdr_trans'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon,
                            dung lam source_event_date o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name  = "ocbchannel" -%}
{% set source_table = "soa_multi_crdr_trans" -%}
{% set business_key_cols = ['id'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_soa_multi_crdr_trans_information': ['tt_no', 'serial_no', 'debit_account_1', 'debit_account_2', 'debit_account_3', 'debit_account_4', 'credit_account_1', 'credit_account_2', 'credit_account_3', 'credit_account_4', 'debit_amount_1', 'debit_amount_2', 'debit_amount_3', 'debit_amount_4', 'credit_amount_1', 'credit_amount_2', 'credit_amount_3', 'credit_amount_4', 'payment_details', 'trans_date', 'datetime_created', 'cif', 'trans_type', 'status', 'err_message', 'last_updated', 'prev_status', 'channel', 'currency', 'user_created', 'user_approved', 'processing_by', 'branchid'],
    'hashdiff_soa_multi_crdr_trans_party': ['debit_cif', 'cif_withdraw', 'cust_name', 'cust_id_type', 'cust_id_no', 'cust_id_date', 'cust_id_place', 'cust_tax_code', 'cust_address', 'cust_national', 'cust_home_phone', 'account_officer_id', 'apportion_branch_code', 'contract_no', 'pro_partner', 'user_created_t24'],
    'hashdiff_soa_multi_crdr_trans_processing': ['status_trans', 'num_authorize_level', 'num_of_signed', 'user_signed_1', 'user_signed_2', 'user_signed_3', 'user_signed_4', 'user_signed_5', 'is_processing', 'last_access', 'datetime_approved', 'user_deleted', 'datetime_deleted', 'user_reverse_created', 'datetime_reverse', 'override_msg', 'reversed_override_msg', 't24user_created', 't24user_approved', 'is_onegate_trans', 'user_ireve', 'date_ireve', 'user_areve', 'date_areve'],
    'hashdiff_soa_multi_crdr_trans_detail': ['service_type', 'fee_amount', 'trans_type_details_id', 'debit_currency', 'credit_currency', 'exchange_rate', 'value_date', 'booking_date', 'vat_form', 'vat_inv_code', 'vat_inv_serial', 'vat_inv_date', 'vat_inv_goods', 'vat_rate', 'vat_amount', 'transaction_code', 'gw_log_id', 'net_amount', 'amount_local_2', 'virtual_account', 'virtual_account_name', 'nice_acc', 'nice_acc_price', 'nice_acc_feeoff', 'credit_card_number', 'credit_card_type', 'credit_card_account', 'credit_card_token_number', 'credit_card_pay_trans_id', 'credit_card_name', 'credit_card_cif', 'ref_trans_id', 'ref_trans_no', 'debit_type', 'other_info', 'cheque_numbers'],
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
  - Cot hashdiff theo hashdiff_satellite_dict
  - Cot record_source, source_event_date, load_timestamp
------------------------------------------------------------------------
*/

{% if execute -%}
{{ stage(source_table=source_table
        ,business_key_cols=business_key_cols
        ,hashdiff_satellite_dict=hashdiff_satellite_dict
        ,source_event_date_col=source_event_date_col
        ,source_name = source_name)
}}
{% endif -%}
