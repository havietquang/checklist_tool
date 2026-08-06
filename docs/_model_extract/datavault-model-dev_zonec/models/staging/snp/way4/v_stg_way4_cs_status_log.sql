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
    alias = 'v_stg_way4_cs_status_log',
    materialized = 'view',
    tags = ['way4', 'card', 'contract', 'device', 'entity', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('way4'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('ows_cs_status_log'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['client__oid']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('bank_date'),
                            dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name  = "way4" -%}
{% set source_table = "ows_cs_status_log" -%}
{% set business_key_cols = ['client__oid'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_acnt_contract_cs_status_log': ['status_date', 'bank_date_to', 'start_local_date', 'end_local_date', 'status_type', 'status_value', 'status_value_prev', 'is_active', 'ext_data', 'descript', 'event_action', 'event_code', 'officer', 'bank_date', 'value_extension', 'usage_action', 'usage_object', 'storno_plan', 'cre_by_storno_plan', 'td_cons__oid'],
    'hashdiff_device_cs_status_log': ['status_date', 'bank_date_to', 'start_local_date', 'end_local_date', 'status_type', 'status_value', 'status_value_prev', 'is_active', 'ext_data', 'descript', 'event_action', 'event_code', 'officer', 'bank_date', 'value_extension', 'usage_action', 'usage_object', 'storno_plan', 'cre_by_storno_plan', 'td_cons__oid'],
    'hashdiff_client_cs_status_log': ['status_date', 'bank_date_to', 'start_local_date', 'end_local_date', 'status_type', 'status_value', 'status_value_prev', 'is_active', 'ext_data', 'descript', 'event_action', 'event_code', 'officer', 'bank_date', 'value_extension', 'usage_action', 'usage_object', 'storno_plan', 'cre_by_storno_plan', 'td_cons__oid'],
    'hashdiff_liability_contract_cs_status_log' : ['status_date', 'bank_date_to', 'start_local_date', 'end_local_date', 'status_type', 'status_value', 'status_value_prev', 'is_active', 'ext_data', 'descript', 'event_action', 'event_code', 'officer', 'bank_date', 'value_extension', 'usage_action', 'usage_object', 'storno_plan', 'cre_by_storno_plan', 'td_cons__oid'],
    'hashdiff_card_cs_status_log': ['status_date', 'bank_date_to', 'start_local_date', 'end_local_date', 'status_type', 'status_value', 'status_value_prev', 'is_active', 'ext_data', 'descript', 'event_action', 'event_code', 'officer', 'bank_date', 'value_extension', 'usage_action', 'usage_object', 'storno_plan', 'cre_by_storno_plan', 'td_cons__oid']
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
{%- set columns = get_columns(source(source_name, source_table)) -%}
{%- set cols_name = [] -%}
{%- for column in columns -%}{%- do cols_name.append(column.name) -%}{%- endfor -%}

{%- set raw_sql %}
select
    --HASH KEY
    {{ hash_column(business_key_cols, source_name) }} as hashkey,

    --ALL COLUMNS FROM SOURCE TABLE
    {% for column in columns %}{{ column.name }},
    {% endfor %}

    --HASHDIFF FULL
    {{ hash_column(cols_name, source_name) }} as hashdiff_full,

    --HASHDIFF SATELLITES
    {% for k, v in hashdiff_satellite_dict.items() %}{{ hash_column(v, source_name) }} as {{ k }},
    {% endfor %}

    --TIME & SOURCE COLUMNS
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    '{{ source_name }}' as record_source,
    cast(current_timestamp as timestamp) as load_timestamp

from {{ source(source_name, source_table) }}
where {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
{%- endset %}

{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=hashdiff_satellite_dict,
    source_event_date_col=source_event_date_col,
    source_event_date_dttype=source_event_date_dttype,
    source_name=source_name,
    raw_sql=raw_sql
) }}
{% endif -%}
