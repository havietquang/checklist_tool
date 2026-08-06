/*
================================================================================
DBT CONFIGURATION GUIDE
================================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<ten_nguon>'] = filter khi run (dbt run --select tag:<ten_nguon>)
================================================================================
*/
{{ config(
    alias = 'effsat_link_crm_user_manager',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_crm_user_manager_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['crm', 'crm_user_structure', 'zonec']
) }}

{% set source_model = 'v_stg_crm_crm_user_structure' %}
{% set source_name = 'crm' %}
{% set source_table = 'crm_user_structure' %}
{% set link_model = 'link_crm_user_manager' %}
{% set unique_key = 'link_crm_user_manager_hashkey' %}

{{ effsat(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = ['user_id', 'user_manager_id'],
    link_model = link_model
) }}
