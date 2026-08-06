/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record mới/thay đổi
                    : 'table' = full load
                    : 'view' = chỉ tạo view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chỉ insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khóa định danh record (thường: hub_hashkey + hashdiff)
skip_matched_step   : true = bỏ record không đổi → tăng performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['omni'] = filter khi run (dbt run --select tag:omni)
====================================================================
*/

{{ config(
    alias = 'sat_data_sharing_consent_other',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['data_sharing_consent_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['omni', 'data_sharing_consent', 'phase2', 'all']
) }}

{% set source_name = 'omni' %}
{% set source_table = 'customer_data_sharing_consent' %}
{% set hashdiff_col = 'hashdiff_data_sharing_consent_other' %}
{% set hub_hashkey = 'data_sharing_consent_hashkey' %}
{% set source_model = 'v_stg_omni_customer_data_sharing_consent' %}
{% set list_cols = [
    'created_at',
    'updated_at',
    'tracking_schema',
    'tracking_item',
    'additions'
] %}
{% set raw_sql = None %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
