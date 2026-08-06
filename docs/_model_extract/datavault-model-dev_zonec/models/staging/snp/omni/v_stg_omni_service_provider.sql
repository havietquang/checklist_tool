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
    alias = 'v_stg_omni_service_provider',
    materialized = 'view',
    tags = ['omni', 'reference', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('omni'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('service_provider'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('least(modified_at, created_at)'),
                            dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name  = "omni" -%}
{% set source_table = "service_provider" -%}
{% set business_key_cols = ['id', 'provider_code'] -%}
{% set list_cols = ['id', 'provider_code', 'provider_name', 'provider_icon', 'services_id', 'service_code', 'provider_group_code', 'provider_group_name', 'auto_bill', 'title', 'image', 'created_by', 'modified_by', 'provider_group_service_id', 'prop1', 'prop2', 'prop3', 'prop4', 'prop5', 'gateway_id', 'visible', 'allow_credit_card', 'content_en', 'content_vi', 'content_reason', 'provider_order', 'save_my_bill', 'module', 'group_service', 'has_fee', 'allow_in_group', 'allow_fav_trans', 'alt_provider_code', 'alt_gateway_id', 'content_ko', 'content_ja', 'auto_bill_permission', 'manual_bill_permission'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict = None -%}

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
        ,source_name=source_name
        ,list_cols=list_cols
        )
}}
{% endif -%}

