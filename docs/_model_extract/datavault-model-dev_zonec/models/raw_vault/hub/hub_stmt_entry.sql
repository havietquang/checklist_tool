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
    alias = 'hub_stmt_entry',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['stmt_entry_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'accounting', 'phase1', 'all']
) }}

{% set source_name = 't24' %}
{% set unique_key = 'stmt_entry_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 't24_stmt_entry' %}
{% set source_model = 'v_stg_t24_t24_stmt_entry' %}

{%- set raw_sql -%}
SELECT
    hashkey AS {{ unique_key }},
    {{ business_key }} AS business_key,
    source_event_date,
    CONCAT('{{ source_name }}', '__', '{{ source_table }}') AS record_source,
    CURRENT_TIMESTAMP AS load_timestamp
FROM {{ ref(source_model) }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')

UNION

SELECT
    {{ hash_column(['t_y_key_det'], source_name) }} AS {{ unique_key }},
    t_y_key_det AS business_key,
    DATE '2024-12-31' AS source_event_date,
    CONCAT('{{ source_name }}', '__', 't24_line_mvmt_toanhang') AS record_source,
    CURRENT_TIMESTAMP AS load_timestamp
FROM {{ ref('v_stg_t24_t24_line_mvmt_toanhang') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND t_xref_nxt_version LIKE 'STMT.ENTRY%'
  AND t_y_key_det IS NOT NULL
  AND NOT EXISTS (
      SELECT 1
      FROM {{ ref(source_model) }}
      WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
        AND id = t_y_key_det
  )
{%- endset %}
/*
========================================================================
HUB MACRO PARAMETERS
========================================================================
  - source_model : Ten cua model/view nguon. VD: 'v_stg_t24_t24_ac_locked_events'.
  - source_name  : Ten he thong nguon (Record Source).
  - source_table : Ten bang nguon business duoc dua vao metadata.
  - unique_key   : Ten cot Hash Key cua Hub (Primary Key cua bang Hub).
  - business_key : Ten cot Business Key tu nguon.
========================================================================
*/

-- Su dung hub macro voi cac tham so native
{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key,
    raw_sql = raw_sql
) }}




