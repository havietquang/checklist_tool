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
    alias = 'hub_clearing_citad',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['clearing_citad_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'transaction', 'phase1', 'all']
) }}

{% set source_name = 't24' %}
{% set unique_key = 'clearing_citad_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 't24_vmbl_int_clr_citad' %}
{% set source_model = 'v_stg_t24_t24_vmbl_int_clr_citad' %}
{% set funds_transfer_source_table = 't24_funds_transfer' %}
{% set funds_transfer_source_model = 'v_stg_t24_t24_funds_transfer' %}

{% set raw_sql -%}
WITH unioned_source AS (
    SELECT
        hashkey AS {{ unique_key }},
        trim(CAST(id AS string)) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', '{{ source_table }}') AS record_source,
        load_timestamp,
        1 AS source_priority
    FROM {{ ref(source_model) }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND id IS NOT NULL
      AND trim(CAST(id AS string)) <> ''

    UNION ALL

    SELECT
        {{ hash_column(['t_clearing_id'], source_name) }} AS {{ unique_key }},
        trim(CAST(t_clearing_id AS string)) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', '{{ funds_transfer_source_table }}') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref(funds_transfer_source_model) }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND t_clearing_id IS NOT NULL
      AND trim(CAST(t_clearing_id AS string)) <> ''
),
deduped AS (
    SELECT
        {{ unique_key }},
        business_key,
        source_event_date,
        record_source,
        load_timestamp,
        row_number() OVER (
            PARTITION BY {{ unique_key }}
            ORDER BY source_priority
        ) AS rn
    FROM unioned_source
    WHERE business_key IS NOT NULL
      AND trim(CAST(business_key AS string)) <> ''
)
SELECT
    {{ unique_key }},
    business_key,
    source_event_date,
    record_source,
    load_timestamp
FROM deduped
WHERE rn = 1
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
    source_name = source_name,
    unique_key = unique_key,
    raw_sql = raw_sql
) }}





