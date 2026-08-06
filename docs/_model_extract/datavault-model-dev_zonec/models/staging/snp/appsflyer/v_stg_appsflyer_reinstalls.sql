/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['appsflyer'] = filter khi run (dbt run --select tag:appsflyer)
====================================================================
*/

{{ config(
    alias = 'v_stg_appsflyer_reinstalls',
    materialized = 'view',
    tags = ['appsflyer', 'reinstalls', 'phase2', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('appsflyer'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('account_information'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['appsflyer_id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : None = nguon khong co cot ngay su kien ro rang;
                            macro se dung ngay load thay the.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name  = "appsflyer" -%}
{% set source_table = "reinstalls" -%} 
{% set business_key_cols = ['appsflyer_id'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_reinstalls_event': ['install_time', 'event_time', 'event_name', 'event_value', 'event_revenue', 'event_revenue_currency', 'event_revenue_usd', 'event_source', 'is_receipt_validated', 'attributed_touch_type', 'attributed_touch_time', 'partner', 'media_source', 'channel', 'keywords', 'campaign', 'campaign_id', 'adset', 'adset_id', 'ad', 'ad_id', 'ad_type', 'site_id', 'sub_site_id', 'sub_param_1', 'sub_param_2', 'sub_param_3', 'sub_param_4', 'sub_param_5', 'carrier', 'cost_model', 'cost_value', 'cost_currency', 'contributor_1_partner', 'contributor_1_media_source', 'contributor_1_campaign', 'contributor_1_touch_type', 'contributor_1_touch_time', 'contributor_2_partner', 'contributor_2_media_source', 'contributor_2_campaign', 'contributor_2_touch_type', 'contributor_2_touch_time', 'contributor_3_partner', 'contributor_3_media_source', 'contributor_3_campaign', 'contributor_3_touch_type', 'contributor_3_touch_time', 'is_retargeting', 'retargeting_conversion_type', 'attribution_lookback', 'reengagement_window', 'is_primary_attribution'],
    'hashdiff_reinstalls_device': ['city', 'wifi', 'operator', 'language', 'advertising_id', 'idfa', 'android_id', 'customer_user_id', 'imei', 'idfv', 'platform', 'device_type', 'os_version', 'app_version', 'sdk_version', 'app_id', 'app_name', 'bundle_id', 'country_code', 'dma', 'ip', 'postal_code', 'region', 'state', 'user_agent', 'http_referrer', 'original_url']
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
