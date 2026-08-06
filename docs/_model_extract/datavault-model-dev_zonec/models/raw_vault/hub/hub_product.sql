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
tags                : ['way4'] = filter khi run (dbt run --select tag:way4)
====================================================================
*/
{{ config(
    alias = 'hub_product',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['product_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'product', 'phase1', 'all']
) }}

{% set source_name = 'way4' %}
{% set unique_key = 'product_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 'appl_product' %}
{% set source_model = 'v_stg_way4_appl_product' %}

{% set raw_sql -%}
    SELECT 
        hashkey AS product_hashkey,
        id AS business_key,
        source_event_date,
        CONCAT(CAST('way4' AS string), '__', 'appl_product') AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM {{ ref('v_stg_way4_appl_product') }} 
    WHERE AMND_STATE = 'A'
{%- endset %}

-- Su dung hub macro voi cau lenh raw_sql tuy chinh
{{ hub(raw_sql = raw_sql, source_name = source_name, source_table = source_table, business_key = business_key) }}





