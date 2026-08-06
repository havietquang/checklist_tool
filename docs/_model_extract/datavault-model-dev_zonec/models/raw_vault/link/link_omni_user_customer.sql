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
    alias = 'link_omni_user_customer',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_omni_user_customer_hashkey'],
    skip_matched_step = true,
    tags = ['omni','user_omni', 'phase1', 'all']
) }}

-- Extraction
{% set source_name = 'omni' %}
{% set source_table = 'en_user' %}
{% set omni_user_business_key_cols = ['id'] %}


{%- set raw_sql -%}
SELECT   
    sha2(
    COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
    CASE
        WHEN regexp_extract(additions, '"cif":"([0-9]+)"', 1) IS NULL THEN ''
        ELSE TRIM(CAST(regexp_extract(additions, '"cif":"([0-9]+)"', 1) AS string))
    END
    , 256) AS link_omni_user_customer_hashkey,

    {{ hash_column(omni_user_business_key_cols, source_name) }} AS omni_user_hashkey,

    sha2(
        CASE
            WHEN regexp_extract(additions, '"cif":"([0-9]+)"', 1) IS NULL THEN ''
            ELSE TRIM(CAST(regexp_extract(additions, '"cif":"([0-9]+)"', 1) AS string))
        END
    , 256) AS customer_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{source_table}}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_omni_en_user') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND id is not null
AND regexp_extract(additions, '"cif":"([0-9]+)"', 1) is not null
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

