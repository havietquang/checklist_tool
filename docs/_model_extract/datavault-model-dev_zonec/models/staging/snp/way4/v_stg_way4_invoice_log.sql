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
    alias = 'v_stg_way4_invoice_log',
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
{% set source_table = "ows_invoice_log" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_invoice_log_information': ['eff_date', 'rep_date', 'due_date', 'invoice_amount', 'paid_amount', 'written_off_amount', 'invoice_status', 'invoice_status_pre', 'invoice_code', 'invoice_ref_number', 'curr', 'invoice_group', 'instalment_plan', 'inst_chain_idt', 'inst_fee__id', 'contract_for', 'instalment_scheme', 'invoice_log__oid', 'acnt_contract__oid', 'doc_id'],
    'hashdiff_invoice_log_detail': ['posting_details', 'balance_code', 'creation_type', 'action_code', 'amount_type', 'debt_type', 'sort_code', 'invoice_details', 'invoice_event', 'partition_key', 'creation_date', 'last_updated', 'begin_date', 'end_date'],
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
