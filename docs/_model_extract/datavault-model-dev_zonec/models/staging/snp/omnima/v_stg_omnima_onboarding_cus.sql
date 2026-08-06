/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['omnima'] = filter khi run (dbt run --select tag:omnima)
====================================================================
*/

{{ config(
    alias = 'v_stg_omnima_onboarding_cus',
    materialized = 'view',
    tags = ['omnima', 'onboarding_cus', 'zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('omnima'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('onboarding_cus'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : None = nguon khong co cot ngay su kien ro rang;
                            macro se dung ngay load thay the.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name  = "omnima" -%}
{% set source_table = "onboarding_cus" -%}
{% set business_key_cols = ['id'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_onbroading_cus_information': ['creat_by', 'creat_dt', 'updt_by', 'updt_dt', 'birthday', 'crefnum', 'contact_address', 'contact_address_district', 'contact_address_province', 'contact_address_ward', 'custgroup_type', 'email', 'fullname', 'gender', 'is_exist_bankaccount', 'is_exist_debitcard', 'is_exist_ebuser', 'is_open_atm', 'is_receive_physicalcard', 'is_receive_virtualcard', 'legalidnum', 'legalidtype', 'legaliid_expired_date', 'legaliid_issued_date', 'legaliid_issued_location', 'marital_status', 'mobilenumber', 'nationality', 'prefnum', 'permanent_address', 'permanent_address_district', 'permanent_address_province', 'permanent_address_ward', 'professional_name', 'register_fail_date', 'register_status', 'trans_method', 'transaction_return', 'transaction_return_msg', 'input_date', 'cif', 'appsflyer_id', 'address_street_line', 'check_nfc_result', 'chip_photo_path', 'first_name', 'is_nfc', 'last_name', 'province_name', 'verify_id_chip_status'],
    'hashdiff_onbroading_cus_onbroading': ['step_authorize_status', 'step_check_aml', 'executed_register', 'facematching_status', 'full_go_step', 'image_id_facematching', 'image_id_legalid', 'image_id_selfie', 'image_id_ocr', 'legalid_status', 'liveness_selfie_score', 'liveness_selfie_status', 'meeting_address', 'meeting_address_district', 'meeting_address_province', 'meeting_address_ward', 'meeting_bank_brank_code', 'meeting_date', 'meeting_time_from', 'meeting_time_to', 'meeting_type', 'number_failed_verify_legalid_sanity', 'number_failed_verify_legalid_tampering', 'number_failed_verify_selfie_sanity_liveness', 'meeting_note', 'ocrmatching_status', 'step_verify_ocr', 'sanity_legalid_score', 'sanity_legalid_status', 'sanity_legalid_verdit', 'sanity_selfie_score', 'sanity_selfie_status', 'sanity_selfie_verdit', 'step_verify_selfie', 'step_verify_facematching', 'step_verify_legalid', 'step_register_status', 'tampering_legalid_score', 'tampering_legalid_status', 'tampering_legalid_verdit'],
    'hashdiff_onbroading_cus_detail': ['legalidlabel1', 'legalidlabel2', 'number_failed_verify_selfie_liveness', 'number_failed_verify_selfie_sanity', 'sent_data_to_crm', 'lst_fatca', 'utm_source', 'card_bank_branch_code', 'card_holder_name', 'card_number', 'card_received_address', 'card_received_district_code', 'card_received_product_code', 'card_received_province_code', 'card_received_type', 'card_received_ward_code', 'step_open_debit_card', 'token_number', 'referral_code', 'old_legal_id_exist_status', 'verify_response', 'hyper_result', 'black_list', 'lognote', 'eb_package_type', 'deeplink', 'legalid_issued_location_code', 'newfo_transferred', 'appsflyer_pid', 'customer_updated_status_infor', 'customer_flow_type']
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
