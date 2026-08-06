/*
========================================================================
DBT CONFIGURATION GUIDE
========================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias        : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['way4'] = filter khi run (dbt run --select tag:way4)
========================================================================
*/

{{ config(
    alias = 'v_stg_way4_usage_action',
    materialized = 'view',
    tags = ['way4', 'contract', 'phase2', 'all']
) }}


/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('way4'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon, dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat cua entity.
  - source_event_date_col : Cot ngay su kien tu nguon, dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach cot tuong ung.
========================================================================
*/

{% set source_name = "way4" -%}
{% set source_table = "ows_usage_action" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_usage_action_information': ['event_type', 'event_type_next', 'con_cat', 'group_code', 'custom_event_code', 'event_details', 'base_amount', 'base_curr', 'fee_type', 'posting_status', 'cl_stop_list', 'client_stop_list', 'next_action', 'switch_tag', 'standing_order__id', 'usage_limiter__id', 'usage_action__oid', 'process_log__id', 'target_doc', 'partition_key', 'acnt_contract__id', 'doc'],
    'hashdiff_usage_action_date': ['record_date', 'start_date', 'end_date', 'start_local_date', 'end_local_date'],
    'hashdiff_usage_action_state': ['old_status', 'new_status', 'old_pack', 'new_pack', 'old_scheme', 'new_scheme', 'old_beh_type', 'new_beh_type'],
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
        ,source_name=source_name)
}}
{% endif -%}
