/*
========================================================================
DBT CONFIGURATION GUIDE
========================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['way4'] = filter khi run (dbt run --select tag:way4)
========================================================================
*/

{{ config(
    alias = 'v_stg_way4_appl_product',
    materialized = 'view',
    tags = ['way4', 'card', 'contract', 'device', 'product', 'transaction', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('way4'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('ows_appl_product'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('amnd_date'),
                            dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name  = "way4" -%}
{% set source_table = "ows_appl_product" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_product_information': ['code', 'code_2', 'code_3', 'internal_code', 'name', 'main_product', 'product_group', 'service_pack', 'acc_scheme', 'tariff_domain', 'custom_data', 'is_active', 'product_status', 'icon', 'is_ready', 'ccat', 'pcat', 'f_i', 'client_type', 'con_cat', 'serv_pack_type', 'contract_role', 'base_relation', 'liab_category', 'report_type', 'contr_type', 'contr_subtype', 'appl_pr_group__id'],
    'hashdiff_product_date': ['date_from', 'date_to', 'date_scheme'],
    'hashdiff_product_limit': ['max_credit_limit', 'min_credit_limit', 'default_credit_limit', 'n_contracts', 'scoring_model', 'check_available', 'check_usage'],
    'hashdiff_product_reference': ['tariff_domain_template', 'copy_from_product', 'base_product', 'parent_code', 'reporting_product', 'product_template'],
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
