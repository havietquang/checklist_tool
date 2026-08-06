-- depends_on: {{ ref('v_stg_t24_t24_holiday') }}

{{ config(
    alias = 'ref_holiday',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['ref_holiday_hashkey','year'],
    tags = ['t24', 'reference', 'phase1', 'all']
) }}

{% set raw_sql -%}
    SELECT
        hashkey AS ref_holiday_hashkey,
        right(ID, 4) as year,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
        CONCAT('t24', '__', 't24_holiday') AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp,
        t_january,
        t_february,
        t_march,
        t_april,
        t_may,
        t_june,
        t_july,
        t_august,
        t_september,
        t_october,
        t_november,
        t_december,
        t_weekend_days,
        t_mth_01_table,
        t_mth_02_table,
        t_mth_03_table,
        t_mth_04_table,
        t_mth_05_table,
        t_mth_06_table,
        t_mth_07_table,
        t_mth_08_table,
        t_mth_09_table,
        t_mth_10_table,
        t_mth_11_table,
        t_mth_12_table
    FROM {{ ref('v_stg_t24_t24_holiday') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
    AND ID LIKE 'VN%'
{%- endset %}

{{ raw_sql }}
