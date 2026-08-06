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
tags                : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/
{{ config(
    alias = 'hub_pc_re_stat_line_bal',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['pc_re_stat_line_bal_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'accounting', 'phase1', 'all']
) }}

{% set source_name = 't24' %}
{% set unique_key = 'pc_re_stat_line_bal_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 't24_pc_re_stat_line_bal' %}
{% set source_model = 'v_stg_t24_t24_pc_re_stat_line_bal' %}

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}

