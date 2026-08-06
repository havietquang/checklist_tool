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
    alias = 'effsat_link_xl_ksgn_chung_khach_hang',
    unique_key = ['link_xl_ksgn_chung_khach_hang_hashkey', 'source_event_date'],
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['bpm', 'phase1', 'all']
) }}

{% set source_model = 'v_stg_bpm_xl_ksgn_chung' %}
{% set source_name = 'bpm' %}
{% set source_table = 'xl_ksgn_chung' %}
{% set link_model = 'link_xl_ksgn_chung_khach_hang' %}
{% set unique_key = 'link_xl_ksgn_chung_khach_hang_hashkey' %}

{{ effsat(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = ['ma_giao_dich', 'khach_hang_id'],
    link_model = link_model
) }}

