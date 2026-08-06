/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['esb'] = filter khi run (dbt run --select tag:esb)
====================================================================
*/

{{ config(
    alias = 'v_stg_esb_batch_trans_details',
    materialized = 'view',
    tags = ['esb', 'batch_trans_details', 'zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('esb'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('batch_trans_details'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['trans_id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : None = nguon khong co cot ngay su kien ro rang;
                            macro se dung ngay load thay the.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name  = "esb" -%}
{% set source_table = "batch_trans_details" -%}
{% set business_key_cols = ['trans_id'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_batch_trans_details': ['batch_item_id', 'debit_account', 'credit_account', 'amount_input', 'amount', 'currency', 'cif', 'trans_status', 'transaction_fee', 'recipient_account', 'recipient', 'descriptions', 'bank_code', 'bank_branch_code', 'province_code', 'err_no', 'err_desc', 'batch_item_no', 'validation_code', 'validation_string', 'validation_status', 'recipient_bank_name', 'priority', 'item_type', 't24_trans_no', 'cref_no', 'batch_item_unique_no', 'payment_type', 'created_date', 'updated_date', 'partner_recipient_name', 'partner_validation_status', 'prev_partner_validation_status', 'partner_validation_string', 'partner_query_error_code', 'partner_query_error_msg', 'partner_payment_status', 'partner_payment_error_code', 'partner_payment_error_msg', 'prev_trans_status', 'prev_partner_payment_status', 'partner_item_ref_no', 'debit_account_name', 'refund_status', 'refund_date', 'province_name', 'bank_branch_name', 't24_fee_amount', 't24_value_date', 'isvirtual', 'sub_va_acct', 'processing_at', 'processing_flag', 'transfer_date', 'batch_payment_type', 'emailreceiver', 'processing_email', 'processing_email_pref', 'bactch_guiid', 'ordinal_number', 'des_acc_lio_bank', 'transaction_id_card', 'number_retry', 'retry_date', 'detail_guiid']
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
        ,source_name = source_name)
}}
{% endif -%}
