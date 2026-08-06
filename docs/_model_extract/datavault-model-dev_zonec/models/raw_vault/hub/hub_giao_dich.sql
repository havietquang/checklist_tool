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
    alias = 'hub_giao_dich',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey'],
    skip_matched_step = true,
    tags = ['bpm','phase2', 'phase1', 'all']
) }}

{% set source_name = 'bpm' %}
{% set unique_key = 'giao_dich_hashkey' %}

{% set raw_sql %}
WITH unioned_source AS (
    SELECT
        hashkey AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'giao_dich') AS record_source,
        load_timestamp,
        1 AS source_priority
    FROM {{ ref('v_stg_bpm_giao_dich') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND gd_id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'tdcn_sp_nhu_cau_td') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_tdcn_sp_nhu_cau_td') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND gd_id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'tdcn_chi_tiet_san_pham') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_tdcn_chi_tiet_san_pham') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND gd_id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'tdcn_khoan_cap_td_the') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_tdcn_khoan_cap_td_the') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND gd_id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'tdcn_thu_nhap_tra_no') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_tdcn_thu_nhap_tra_no') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND gd_id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'tdcn_nguoi_dong_vay') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_tdcn_nguoi_dong_vay') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND gd_id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'lich_su_giao_dich') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_lich_su_giao_dich') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND gd_id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS giao_dich_hashkey,
        CAST(ma_giao_dich AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'tc_stk_lich_su') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_tc_stk_lich_su') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND ma_giao_dich IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS giao_dich_hashkey,
        CAST(ma_giao_dich AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'tc_stk_thong_tin_tong_hop') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_tc_stk_thong_tin_tong_hop') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND ma_giao_dich IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'tcstk_thong_tin_chung') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_tcstk_thong_tin_chung') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND gd_id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'tcstk_thong_tin_bao_dam') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_tcstk_thong_tin_bao_dam') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND gd_id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'tcstk_thong_tin_giao_dich') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_tcstk_thong_tin_giao_dich') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND gd_id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'giao_dich_the') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_giao_dich_the') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND gd_id IS NOT NULL

    UNION ALL

    SELECT
        hashkey AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        source_event_date,
        CONCAT('{{ source_name }}', '__', 'ttd_giao_dich_igen') AS record_source,
        load_timestamp,
        2 AS source_priority
    FROM {{ ref('v_stg_bpm_ttd_giao_dich_igen') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
      AND gd_id IS NOT NULL
),
deduped AS (
    SELECT
        giao_dich_hashkey,
        business_key,
        source_event_date,
        record_source,
        load_timestamp,
        row_number() OVER (
            PARTITION BY giao_dich_hashkey
            ORDER BY source_priority
        ) AS rn
    FROM unioned_source
    WHERE business_key IS NOT NULL
      AND trim(CAST(business_key AS string)) <> ''
)
SELECT
    giao_dich_hashkey,
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
