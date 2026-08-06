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
    alias = 'v_stg_way4_item',
    materialized = 'view',
    tags = ['way4', 'accounting', 'phase2', 'all']
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
{% set source_table = "ows_item" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_item_information': ['n_of_cycle', 'cycle_template', 'interest_tariff', 'account_number', 'gl_number', 'acc_cycle_code', 'service_class', 'currency', 'cycle_id', 'cycle_date_to', 'cycle_event', 'date_from', 'date_to', 'due_date', 'due_status', 'account__oid', 'templ_approved_id'],
    'hashdiff_item_balance_rate': ['begin_balance', 'cycle_balance', 'item_total', 'fee_total', 'interest_factor', 'interest_rate', 'interest_fee_rate', 'number_of_docs', 'partition_key'],
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
