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
skip_matched_step   : true = bo record khong doi → tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<ten_nguon>'] = filter khi run (dbt run --select tag:<ten_nguon>)
================================================================================
*/
{{ config(
    alias = 'link_voucher_generate_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_voucher_generate_customer_hashkey'],
    skip_matched_step = true,
    tags = ['omni', 'voucher', 'phase1', 'all']
) }}

{% set source_name = 'omni' %}
{% set voucher_generate_business_key_cols = ['voucher_serial_code'] %}
{%- set raw_sql -%}
SELECT
    {{ hash_column(['voucher_serial_code', 'cif'], source_name) }} AS link_voucher_generate_customer_hashkey,
    {{ hash_column(voucher_generate_business_key_cols, source_name) }} AS voucher_generate_hashkey,
    {{ hash_column(['cif'], source_name) }} AS customer_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('omni' AS string), '__', 'voucher_generate') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ref('v_stg_omni_voucher_generate')}}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd') AND voucher_serial_code IS NOT NULL AND cif IS NOT NULL
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

