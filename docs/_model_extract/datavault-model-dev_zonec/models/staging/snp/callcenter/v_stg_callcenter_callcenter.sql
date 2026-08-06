/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['crm' , 'callcenter'] = filter khi run (dbt run --select tag:crm)
====================================================================
*/

{{ config(
    alias = 'v_stg_callcenter_callcenter',
    materialized = 'view',
    tags = ['crm', 'callcenter', 'contact', 'phase2', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('callcenter'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('callcenter'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ["gcalluuid"]
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('calldate'),
                            dung lam `source_event_date` o downstream.
  - source_table_to_join  : Bang join them ('crm') de bo sung
                            business key cho source chinh.
  - business_key_to_join  : Business Key cua bang join. ['uniqueid']
  - source_event_date_dttype: Kieu du lieu cua cot ngay su kien ('bigint')
                            khi cot khong phai kieu date/timestamp chuan.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name = "callcenter" -%}
{% set source_table = "callcenter" -%}
{% set business_key_cols = ["_id"] -%}
{% set source_table_to_join = "crm" -%}
{% set business_key_to_join = ['uniqueid'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict = {
    'hashdiff_callcenter_information': ['uniqueid', 'gcalluuid', 'accountcode', 'dialid', 'sipserver', 'src', 'dst', 'channel', 'dstchannel', 'queue', 'in_out', 'did_number', 'prefix_detail', 'carrier', 'callername', 'customer_id', 'customer_code', 'customername', 'customercif'],
    'hashdiff_callcenter_outcome': ['calldate', 'calldatetime', 'createtime', 'duration', 'billsec', 'billtime', 'holdtime', 'talktime', 'waitingtime', 'moh_time', 'disposition', 'system_disposition', 'extension_disposition', 'calltype', 'hangup_by', 'connected', 'not_connected', 'processed', 'filename', 'moh_log', 'moh_log_process']
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
        ,source_event_date_col = source_event_date_col
        ,source_event_date_dttype = source_event_date_dttype
        ,source_name = source_name
        )
}}
{% endif -%}