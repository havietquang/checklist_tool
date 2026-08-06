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
    alias = 'sat_payment_history_other',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['payment_history_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['omni', 'payment_order', 'phase2', 'all']
) }}

{% set source_name = 'omni' %}
{% set source_table = 'payment_history' %}
{% set hashdiff_col = 'hashdiff_payment_history_other' %}
{% set hub_hashkey = 'payment_history_hashkey' %}
{% set source_model = 'v_stg_omni_payment_history' %}
{% set list_cols = [
    'detail_code',
    'arrangement_id',
    'core_counter_party_bank_id',
    'counter_party_name',
    'bank_branch',
    'bank_province',
    'created_at',
    'modified_at',
    'created_by',
    'modified_by',
    'additions',
    'prop1',
    'prop2',
    'prop3',
    'prop4',
    'prop5'
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
