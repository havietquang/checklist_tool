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
    alias = 'sat_message_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['message_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['omni', 'message', 'phase2', 'all']
) }}

{% set source_name = 'omni' %}
{% set source_table = 'message' %}
{% set hashdiff_col = 'hashdiff_message_information' %}
{% set hub_hashkey = 'message_hashkey' %}
{% set source_model = 'v_stg_omni_message' %}
{% set list_cols = [
    'uuid',
    'root_message_id',
    'subject',
    'body',
    'is_body_html',
    'category',
    'important',
    'sender',
    'sender_name',
    'sent_date_time',
    'read_receipt',
    'deletable',
    'read_only',
    'content_repo_id',
    'content_path',
    'metric_dimensions',
    'additions',
    'recipient'
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
