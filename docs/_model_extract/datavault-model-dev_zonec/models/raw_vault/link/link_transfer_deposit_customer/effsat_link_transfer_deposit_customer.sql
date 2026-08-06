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
    alias = 'effsat_link_transfer_deposit_customer',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_transfer_deposit_customer_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'deposit', 'phase2', 'all']
) }}

{% set source_model = 'v_stg_t24_t24_transfer_deposit' %}
{% set source_name = 't24' %}
{% set source_table = 't24_transfer_deposit' %}
{% set link_model = 'link_transfer_deposit_customer' %}
{% set unique_key = 'link_transfer_deposit_customer_hashkey' %}

{{ effsat(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = ['id', 'cif_new'],
    link_model = link_model
) }}

