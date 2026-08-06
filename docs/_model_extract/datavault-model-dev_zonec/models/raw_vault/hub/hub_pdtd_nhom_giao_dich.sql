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
tags                : ['bpm'] = filter khi run (dbt run --select tag:bpm)
====================================================================
*/
{{ config(
    alias = 'hub_pdtd_nhom_giao_dich',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['pdtd_nhom_giao_dich_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'phase1', 'all']
) }}

{% set source_name = 'bpm' %}
{% set unique_key = 'pdtd_nhom_giao_dich_hashkey' %}

{% set raw_sql %}
WITH unioned_source AS (
    SELECT
        hashkey AS pdtd_nhom_giao_dich_hashkey,
        CAST(ma_giao_dich AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'pdtd_nhom_giao_dich') AS record_source,
        load_timestamp,
        1 AS source_priority
    FROM {{ ref('v_stg_bpm_pdtd_nhom_giao_dich') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND ma_giao_dich IS NOT NULL

    UNION ALL

    SELECT
        {{ hash_column(['B.ma_giao_dich'], source_name) }} AS pdtd_nhom_giao_dich_hashkey,
        CAST(B.ma_giao_dich AS string) AS business_key,
        A.source_event_date,
        CONCAT('{{ source_name }}', '__', 'pdtd_giao_dich_tin_dung') AS record_source,
        A.load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_pdtd_giao_dich_tin_dung') }} A
    JOIN {{ ref('v_stg_bpm_pdtd_nhom_giao_dich') }} B
        ON A.nhom_giao_dich = B.id
    WHERE A.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND B.ma_giao_dich IS NOT NULL

    UNION ALL

    SELECT
        {{ hash_column(['nvl(B.ma_giao_dich, CAST(A.nhom_giao_dich_id AS string))'], source_name) }} AS pdtd_nhom_giao_dich_hashkey,
        CAST(nvl(B.ma_giao_dich, CAST(A.nhom_giao_dich_id AS string)) AS string) AS business_key,
        A.source_event_date,
        CONCAT('{{ source_name }}', '__', 'h_pdtd_gdich_lsu_pduyet') AS record_source,
        A.load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_h_pdtd_gdich_lsu_pduyet') }} A
    LEFT JOIN {{ ref('v_stg_bpm_pdtd_nhom_giao_dich') }} B
        ON A.nhom_giao_dich_id = B.id
    WHERE A.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND nvl(B.ma_giao_dich, CAST(A.nhom_giao_dich_id AS string)) IS NOT NULL

    UNION ALL

    SELECT
        {{ hash_column(['nvl(B.ma_giao_dich, CAST(A.nhom_giao_dich_id AS string))'], source_name) }} AS pdtd_nhom_giao_dich_hashkey,
        CAST(nvl(B.ma_giao_dich, CAST(A.nhom_giao_dich_id AS string)) AS string) AS business_key,
        A.source_event_date,
        CONCAT('{{ source_name }}', '__', 'h_pdtd_gdich_ctiet_pduyet') AS record_source,
        A.load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_h_pdtd_gdich_ctiet_pduyet') }} A
    LEFT JOIN {{ ref('v_stg_bpm_pdtd_nhom_giao_dich') }} B
        ON A.nhom_giao_dich_id = B.id
    WHERE A.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND A.nhom_giao_dich_id <> 0
),
deduped AS (
    SELECT
        pdtd_nhom_giao_dich_hashkey,
        business_key,
        source_event_date,
        record_source,
        load_timestamp,
        row_number() OVER (
            PARTITION BY pdtd_nhom_giao_dich_hashkey
            ORDER BY source_priority
        ) AS rn
    FROM unioned_source
    WHERE business_key IS NOT NULL
      AND trim(CAST(business_key AS string)) <> ''
)
SELECT
    pdtd_nhom_giao_dich_hashkey,
    business_key,
    source_event_date,
    record_source,
    load_timestamp
FROM deduped
WHERE rn = 1
{% endset %}

{{ hub(
    source_name = source_name,
    unique_key = unique_key,
    raw_sql = raw_sql
) }}
