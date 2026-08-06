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
    alias = 'v_stg_omni_payment_order',
    materialized = 'view',
    tags = ['omni', 'payment_order', 'phase2', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('omni'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('payment_order'),
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
{% set source_table = "payment_order" -%} 
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}
{% set hashdiff_satellite_dict =
{
    'hashdiff_payment_order_classification': ['status', 'bank_status', 'pmt_mode', 'pmt_type', 'priority', 'role', 'entry_class', 'intra_legal_entity', 'remaining_occurrences', 'account_scheme'],
    'hashdiff_payment_order_information' : ['account', 'name', 'amount', 'currency', 'orig_acc_currency', 'send_to_core_datetime', 'delivery_date', 'rejection_reason', 'reason_code', 'reason_text', 'error_description', 'address_line1', 'address_line2', 'street_name', 'town', 'country_sub_division', 'post_code', 'country', 'arrangement_id', 'ext_arrangement_id', 'service_agreement_id', 'additions', 'payment_setup_id', 'approval_id', 'payment_submission_id', 'confirmation_id','bank_reference_id', 'created_at', 'created_by', 'updated_at', 'updated_by'],
    'hashdiff_payment_order_schedule' : ['requested_exec_date', 'start_date', 'end_date', 'frequency', 'every', 'when_execute', 'repetition', 'remaining_occurrences', 'non_working_day_strategy']
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
        ,source_event_date_dttype=source_event_date_dttype
        ,source_name = source_name)
}}
{% endif -%}
