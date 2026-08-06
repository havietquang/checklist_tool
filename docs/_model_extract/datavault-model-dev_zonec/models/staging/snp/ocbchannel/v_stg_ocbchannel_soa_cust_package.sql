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
    alias = 'v_stg_ocbchannel_soa_cust_package',
    materialized = 'view',
    tags = ['ocbchannel', 'soa_cust_package', 'zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('ocbchannel'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('soa_cust_package'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['package_id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : None = nguon khong co cot ngay su kien ro rang;
                            macro se dung ngay load thay the.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name  = "ocbchannel" -%}
{% set source_table = "soa_cust_package" -%}
{% set business_key_cols = ['package_id'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_soa_cust_package_information': ['cif', 'customer_type', 'package_type_id', 'created_date', 'user_created', 'user_approved', 'date_approved', 'is_create_current_acct', 'is_create_sms', 'is_create_ib', 'is_create_mb', 'status', 'status_trans', 'branch_code', 'account_officer', 'start_date', 'end_date', 'user_deleted', 'date_deleted', 'last_access'],
    'hashdiff_soa_cust_package_detail': ['is_processing', 'prev_status', 'fee_account_opt', 'fee_account', 'status_message', 'fee_account_category', 'processing_step', 'partner_id', 'other_atm_account', 'ecom_phone', 'services', 'program', 'source', 'cust_email', 'cust_sms', 'rm_email', 'branch_code_ben', 'is_open_atm', 'ac_middle_man', 'is_dics_fee_nice_ac', 'is_new_omni', 'is_pay_fee']
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
