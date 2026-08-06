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
    alias = 'sat_clevertap_tracking_detail',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['clevertap_tracking_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['omni', 'clevertap_tracking', 'phase2', 'all']
) }}

{% set source_name = 'omni' %}
{% set source_table = 'clevertap_tracking' %}
{% set hashdiff_col = 'hashdiff_clevertap_tracking_detail' %}
{% set hub_hashkey = 'clevertap_tracking_hashkey' %}
{% set source_model = 'v_stg_omni_clevertap_tracking' %}
{% set list_cols = [
    'clevertap_id',
    'event_name',
    'channel',
    'created_at',
    'modified_at',
    'cif'
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
