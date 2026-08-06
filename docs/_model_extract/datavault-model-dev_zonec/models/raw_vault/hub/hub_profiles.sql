/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record (thuong: hub_hashkey + hashdiff)
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['clevertap'] = filter khi run (dbt run --select tag:clevertap)
====================================================================
*/
{{ config(
    alias = 'hub_profiles',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['profiles_hashkey'],
    skip_matched_step = true,
    tags = ['clevertap', 'profiles', 'zonec']
) }}

{% set source_name = 'clevertap' %}
{% set unique_key = 'profiles_hashkey' %}
{% set business_key = "concat(coalesce(identity,''), '||', coalesce(token,''))" %}
{% set source_table = 'profiles' %}
{% set source_model = 'v_stg_clevertap_profiles' %}

{% set raw_sql = None %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}
