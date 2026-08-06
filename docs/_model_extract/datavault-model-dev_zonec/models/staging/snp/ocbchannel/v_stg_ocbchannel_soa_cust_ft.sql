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
    alias = 'v_stg_ocbchannel_soa_cust_ft',
    materialized = 'view',
    tags = ['ocbchannel', 'soa_cust_ft', 'zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('ocbchannel'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('soa_cust_ft'),
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
{% set source_table = "soa_cust_ft" -%}
{% set business_key_cols = ['id'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_soa_cust_ft_information': ['id', 'ft_no', 'serial_no', 'debit_account', 'debit_currency', 'credit_account', 'credit_currency', 'amount', 'payment_details', 'trans_date', 'datetime_created', 'cif', 'branchid', 'status', 'err_message', 'last_updated', 'channel', 'last_access', 'user_created', 'user_approved', 't24_trans_type'],
    'hashdiff_soa_cust_ft_party': ['cust_id_no', 'cust_id_date', 'cust_id_place', 'cust_id_type', 'cust_type', 'cust_address', 'cust_taxcode', 'cust_name', 'cust_phone_no', 'cif_advance', 'cif_deposit', 'fee_charge_cif', 'user_created_t24', 'beneficiary', 'beneficiary_id_no', 'beneficiary_id_date', 'beneficiary_id_place', 'beneficiary_account', 'beneficiary_currency', 'beneficiary_bank', 'beneficiary_bank_branch', 'beneficiary_address', 'bc_bank_sort_code', 'beneficiary_phone', 'adhoc_beneficiary'],
    'hashdiff_soa_cust_ft_processing': ['prev_status', 'secret_question', 'secret_answer', 'is_processing', 'processing_by', 'trans_password', 'paid_status', 'status_trans', 'num_authorize_level', 'num_of_signed', 'user_signed_1', 'user_signed_2', 'user_signed_3', 'user_signed_4', 'user_signed_5', 'datetime_approved', 'processing_step', 'user_deleted', 'datetime_deleted', 'user_reverse_created', 'datetime_reverse', 'user_reverse_approved', 'datetime_reverse_approved', 'override_msg', 'reversed_override_msg'],
    'hashdiff_soa_cust_ft_detail': ['commission_amount', 'commission_option', 'commission_type', 'exchange_rate', 'tax_amount', 'amount_credited', 'fee_charge_acc', 'discount_fee_type', 'discount_fee_amount', 'credit_card_no', 'credit_card_pay_status', 'credit_card_pay_info', 'credit_card_rev_status', 'credit_card_rev_info', 'credit_card_token_number', 'credit_card_pay_trans_id', 'credit_card_cif', 'credit_card_account', 'credit_card_name', 'trans_type', 'ft_type', 'extra_info', 'ref_type', 'ref_no', 'ref_id', 'branch_code_transfer', 'smartlink_type', 'debit_type', 'debit_account_name', 'debit_account_1', 'classify_code', 'virtual_account', 'virtual_account_name', 'ld_no', 'profit_period', 'is_onegate_trans', 'trans_branch_code', 'is_refund', 'refund_account', 'credit_cif', 'credit_account_name'],
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
