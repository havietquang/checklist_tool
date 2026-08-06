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
    alias = 'v_stg_omni_oversea_ft_request',
    materialized = 'view',
    tags = ['omni', 'omni_service', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('omni'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('oversea_ft_request'),
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
{% set source_table = "oversea_ft_request" -%} 
{% set business_key_cols = ['id'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_oversea_ft_request_information': ['purpose_code','currency','req_amount','req_charge_type','internal_reference','external_id','external_reference','status','account_number','account_cur','contract_limit_id','rm_code','rm_name','latest_bpm_comment','lasted_bpm_updated_at'],
    'hashdiff_oversea_ft_request_beneficiary': ['ben_name','ben_address','ben_bank_name','ben_bank_code','ben_bank_address','ben_account_no','beneficiary_branch_code'],
    'hashdiff_oversea_ft_request_related_party': ['related_name','related_legal_id_no','related_address','related_relationship_code'],
    'hashdiff_oversea_ft_request_visa_commit': ['is_debt_visa_bit','visa_commit_date','visa_commit_id','visa_commit_reference'],
    'hashdiff_oversea_ft_request_execution': ['mt103_reference','transferred_amount','transferred_cur','transferred_at','transferred_status','exchange_rate','charge_amt_before','charge_amt','charge_type','discount'],
    'hashdiff_oversea_ft_request_audit': ['created_at','updated_at','created_by','updated_by','deleted']
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
