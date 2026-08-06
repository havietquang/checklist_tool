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
    alias = 'v_stg_ocbchannel_soa_hdtg_da_nang',
    materialized = 'view',
    tags = ['ocbchannel', 'soa_hdtg_da_nang', 'zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('ocbchannel'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('soa_hdtg_da_nang'),
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

{% set source_name  = "ocbchannel" -%}
{% set source_table = "soa_hdtg_da_nang" -%}
{% set business_key_cols = ['id'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_soa_hdtg_da_nang': ['account_no', 'serial_no', 'term', 'open_date', 'mature_date', 'amount', 'currency', 'datetime_created', 'cif', 'rollover_account', 'rollover', 'trans_type', 'category', 'status', 'err_message', 'last_updated', 'prev_status', 'channel', 'branch_id', 'last_access', 'is_processing', 'processing_by', 'user_created', 'debit_account', 'product', 'service_type', 'interest_rate', 'customer_name', 'trans_date', 'debit_account_name', 'account_officer_id', 'user_deleted', 'mobile_no'],
    'hashdiff_soa_hdtg_da_nang_detail': ['user_approved', 'status_trans', 'num_authorize_level', 'num_of_signed', 'user_signed_1', 'user_signed_2', 'user_signed_3', 'user_signed_4', 'user_signed_5', 'datetime_deleted', 'frequency', 'is_schedules', 'calculation_base', 'forward_backward', 'schedule_type', 'ref_officer_id', 'override_msg', 'joint_holder_cif_1', 'relation_code_1', 'joint_notes_1', 'joint_holder_cif_2', 'relation_code_2', 'joint_notes_2', 'user_created_t24', 'pi_key', 'roll_product', 'tutor_cif', 'processing_step', 'extra_info', 'org_term', 'mobile_no_co_owner', 'cust_group']
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
