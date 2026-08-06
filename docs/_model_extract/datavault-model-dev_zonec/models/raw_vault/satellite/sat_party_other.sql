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
    alias = 'sat_party_other',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['party_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['omni', 'party', 'phase2', 'all']
) }}

{% set source_name = 'omni' %}
{% set source_table = 'party' %}
{% set hashdiff_col = 'hashdiff_party_other' %}
{% set hub_hashkey = 'party_hashkey' %}
{% set source_model = 'v_stg_omni_party' %}
{% set list_cols = [
    'access_context_scope',
    'bb_id',
    'email_id',
    'phone_number',
    'legal_entity_id',
    'service_agreement_id',
    'external_id',
    'approval_id',
    'active_party_id',
    'import_id',
    'user_reference',
    'contact_reference',
    'searchable_field_one',
    'searchable_field_two',
    'created_at',
    'updated_at',
    'additions',
    'address_line1',
    'address_line2',
    'street_name',
    'town',
    'country',
    'post_code',
    'country_sub_division'
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
