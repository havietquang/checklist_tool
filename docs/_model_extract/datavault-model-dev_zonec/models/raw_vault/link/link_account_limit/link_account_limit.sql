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
    alias = 'link_account_limit',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_account_limit_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'account', 'phase1', 'all']
) }}

/*
================================================================================
LINK MACRO PARAMETERS
================================================================================
  - raw_sql : Cau SELECT tu custom de truyen truc tiep vao hub macro.
  - raw_sql phai tra ve day du cac cot:
      + source_model       : model/view staging chua du lieu nguon (ten ref duoc dung trong FROM).
      + source_name        : namespace nguon (dung de tao record_source prefix).
      + source_table       : ten bang nguon cu the (dung de tao gia tri record_source).
      + unique_key         : ten cot hash key cua Link target.
      + source_business_key_cols: cot xac dinh duy nhat cung cap cho link hash.
      + foreign_business_key_cols: map hub_hashkey -> cot nguon.

================================================================================
*/

-- Extraction
{% set source_name = 't24' %}
{% set source_table = 't24_account' %}
{% set source_model = 'v_stg_t24_t24_account' %}
{% set unique_key = 'link_account_limit_hashkey' %}

{%- set raw_sql -%}

WITH limit_source AS (
    SELECT DISTINCT
        id,
        t_customer,
        t_limit_ref,
        CONCAT(
            CAST(t_customer AS string),
            '.',
            CONCAT(
                LPAD(get(SPLIT(CAST(t_limit_ref AS string), '\\.'), 0), 7, '0'),
                '.',
                get(SPLIT(CAST(t_limit_ref AS string), '\\.'), 1)
            )
        ) AS limit_business_key,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date
    FROM {{ ref('v_stg_t24_t24_account') }}
)
SELECT
    {{ hash_column(['id', 'limit_business_key'], source_name) }} AS link_account_limit_hashkey,
    {{ hash_column(['id'], source_name) }} AS account_hashkey,
    {{ hash_column(['limit_business_key'], source_name) }} AS limit_hashkey,
    source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM limit_source
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND id IS NOT NULL
  AND t_customer IS NOT NULL
  AND t_limit_ref IS NOT NULL
  AND t_limit_ref LIKE '%.%'
{%- endset %}

{{ link(raw_sql = raw_sql) }}



