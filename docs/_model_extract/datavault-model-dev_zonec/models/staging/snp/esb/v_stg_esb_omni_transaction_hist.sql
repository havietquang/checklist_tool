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
    alias = 'v_stg_esb_omni_transaction_hist',
    materialized = 'view',
    tags = ['esb', 'omni_transaction_hist', 'zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('esb'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('omni_transaction_hist'),
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
{% set source_table = "omni_transaction_hist" -%}
{% set business_key_cols = ['trans_id'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_omni_transaction_hist_information': ['ref_id', 'payment_type', 'product_type', 'created_datetime', 'execute_date', 'cif', 'debit_account_no', 'credit_account', 'amount', 'currency', 'remarks', 'eb_user_id', 'service_code', 'service_provider_code', 'bill_code', 't24_trans_no', 'source_type'],
    'hashdiff_omni_transaction_hist_detail': ['operation_status', 'stmt_id', 'user_created', 'customer_id', 'sender', 'recipient', 'bank_code', 'bank_branch_code', 'province_code', 'clearing_network', 'qty', 'bill_sourcedata', 'mobile_phone_number', 'par_value', 'student_code', 'university_code', 'course_type', 'sourcedata', 'partner_id', 'payment_code', 'recipient_card_number', 'ewallet_phonenumber', 'payment_status', 'exchange_rate', 'amount_lcy', 'currency_lcy', 'telco_provider', 'discount_amount', 'recipient_card_account_no', 'recipient_customer_id', 'fee_type', 'debit_acct_currency', 'request_ref_id', 'fee_amount', 'virtual_account', 'virtual_account_name', 'card_no', 'card_account_no', 'phone_no', 'exchange_coin_quan', 'channel', 'batch_id']
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
