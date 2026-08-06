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
    alias = 'v_stg_omni_od_registration',
    materialized = 'view',
    tags = ['omni', 'od_registration', 'phase2', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('omni'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('od_registration'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('least(updated_at, created_at)'),
                            dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name  = "omni" -%}
{% set source_table = "od_registration" -%} 
{% set business_key_cols = ['id'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_od_registration_limit': ['requested_limit_amount' ,'approved_limit_amount' ,'interest_rate'],
    'hashdiff_od_registration_agreement': ['contract_file_id', 'result_file_id', 'approval_file_id', 'contract_bill_code', 'first_approval_agreement_uuid', 'first_approval_bill_code', 'second_approval_agreement_uuid', 'second_approval_bill_code', 'ecm_approval_document_id', 'ecm_contract_document_id', 'prepare_certificate_request_id', 'confirmation_id', 'approval_agreement_id'],
    'hashdiff_od_registration_date': ['due_date', 'effective_date', 'requested_date', 'issued_date', 'created_at', 'updated_at'],
    'hashdiff_od_registration_information': ['status', 'full_name', 'identity_number', 'email', 'phone_number', 'address', 'username', 'issued_by', 'created_by', 'updated_by']
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
