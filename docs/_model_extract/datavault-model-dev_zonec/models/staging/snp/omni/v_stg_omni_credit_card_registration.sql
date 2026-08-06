/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['omni'] = filter khi run (dbt run --select tag:omni)
====================================================================
*/

{{ config(
    alias = 'v_stg_omni_credit_card_registration',
    materialized = 'view',
    tags = ['omni', 'cc_registration', 'phase2', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('omni'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('credit_card_registration'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('least(updated_date, created_date)'),
                            dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name  = "omni" -%}
{% set source_table = "credit_card_registration" -%} 
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}
{% set hashdiff_satellite_dict = {
    'hashdiff_credit_card_registration_customer_info': ['number_of_dependents', 'job', 'company_address', 'company_address_info', 'company_name', 'type_of_labor_contract', 'position', 'working_time'],
    'hashdiff_credit_card_registration_financial_profile': ['income_method', 'debt_expenses_to_pay_other_credit_institutions', 'real_monthly_income', 'living_expenses', 'salary_income', 'business_income', 'vehicle_rental_income', 'real_estate_rental_income', 'other_income'],
    'hashdiff_credit_card_registration_flow': ['ekyc_type', 'face_liveness_status', 'face_matching_status', 'face_sanity_status', 'id_card_ocr_status', 'id_card_sanity_status', 'in_import_list', 'signed_contract_file_path', 'contract_file_path', 'document_id', 'agreement_uuid', 'contract_no'],
    'hashdiff_credit_card_registration_information': ['card_limit_approved', 'created_date', 'updated_date', 'status', 'sale_code', 'personal_rank', 'personal_rank_start', 'personal_rank_renew', 'group_personal_rank', 'card_issuance_type', 'process_type', 'policy_groups'],
    'hashdiff_credit_card_registration_introduce': ['introduce_name', 'introduce_code', 'referral_code', 'reference_name', 'reference_phone_number'],
    'hashdiff_credit_card_registration_other': ['birthday', 'contact_address', 'customer_name', 'email', 'id_card_tampering_status', 'legal_id_num', 'legal_issue_date', 'legal_issue_place', 'limit_suggest', 'marital_status', 'legal_id_num_other', 'permanent_address', 'phone_number', 'product_code', 'product_name', 'branch_name', 'branch_code', 'card_repayment_type', 'card_repayment_account_no', 'delivery_address', 'old_legal_id_no', 'legal_id_type', 'legal_expired_date', 'gender', 'sale_name', 'nationality', 'education_level', 'card_token_number', 'spouse_name', 'spouse_legal_type', 'spouse_legal_id', 'product_code_offer', 'product_name_offer', 'product_code_offer_list', 'spouse_phone_number', 'relationship_type', 'reference_id'],
} -%}

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
        ,source_name = source_name)
}}
{% endif -%}
