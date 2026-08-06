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
    alias = 'link_callcenter_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_callcenter_customer_hashkey'],
    skip_matched_step = true,
    tags = ['callcenter', 'contact', 'phase2', 'all']
) }}

-- Extraction
{% set source_name = 'callcenter' %}
{% set source_table = 'callcenter' %}
{% set call_business_key_cols = ['_id'] %}

{%- set raw_sql -%}
WITH hash_multival AS
(
    SELECT distinct
        _id,
        explode(from_json(customercif, 'array<string>')) as cif,
        {{ hash_column(call_business_key_cols,source_name) }} AS callcenter_hashkey,
        source_event_date
    FROM {{ ref('v_stg_callcenter_callcenter') }}
    WHERE customercif IS NOT NULL
),
link_rows AS
(
    SELECT
        {{ hash_column(['_id', 'cif'], source_name) }} AS link_callcenter_customer_hashkey,
        callcenter_hashkey,
        {{ hash_column(['cif'], source_name) }} AS customer_hashkey,
        source_event_date,
        CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM hash_multival
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
    AND cif IS NOT NULL
    AND _id IS NOT NULL
),
dedup AS
(
    -- Dedup theo chinh hashkey: moi link_callcenter_customer_hashkey chi giu 1 dong
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY link_callcenter_customer_hashkey
            ORDER BY source_event_date DESC, load_timestamp DESC
        ) AS rn
    FROM link_rows
)
SELECT
    link_callcenter_customer_hashkey,
    callcenter_hashkey,
    customer_hashkey,
    source_event_date,
    record_source,
    load_timestamp
FROM dedup
WHERE rn = 1
{%- endset %}
-------------
--Main part
{{ link(raw_sql = raw_sql) }}
