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
    alias = 'effsat_link_od_registration_deposit',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_od_registration_deposit_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['omni', 'od_registration', 'phase1', 'all']
) }}

{% set source_model = 'v_stg_omni_od_linked_deposit' %}
{% set source_name = 'omni' %}
{% set source_table = 'od_linked_deposit' %}
{% set link_model = 'link_od_registration_deposit' %}
{% set unique_key = 'link_od_registration_deposit_hashkey' %}

{{ effsat(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = ['od_registration_id', 'deposit_account_no'],
    link_model = link_model
) }}

