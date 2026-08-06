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
    alias = 'sat_party_account_other',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['party_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['omni', 'account_information', 'party', 'phase2', 'all']
) }}

{% set source_name = 'omni' %}
{% set source_table = 'account_information' %}
{% set hashdiff_col = 'hashdiff_party_account_other' %}
{% set hub_hashkey = 'party_hashkey' %}
{% set source_model = 'v_stg_omni_account_information' %}
{% set list_cols = [
    'uuid',
    'alias',
    'phone_number',
    'email',
    'external_id',
    'party_id',
    'additions',
    'bank_address_source',
    'bank_address_line1',
    'bank_address_line2',
    'bank_street_name',
    'bank_town',
    'bank_country',
    'bank_post_code',
    'bank_country_sub_division',
    'acc_holder_addr_line1',
    'acc_holder_addr_line2',
    'acc_holder_street_name',
    'acc_holder_town',
    'acc_holder_country',
    'acc_holder_post_code',
    'acc_holder_country_sub_div'
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
