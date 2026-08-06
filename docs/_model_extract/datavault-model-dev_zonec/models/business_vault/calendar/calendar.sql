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
unique_key          : Khoa dinh danh record cua AS OF DATE
skip_matched_step   : true = bo record khong doi -> tang performance
tags                : ['<source_name>'] = filter khi run (dbt run --select tag:<source_name>)
====================================================================
*/
{{ config(
    alias = 'calendar',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['msr_prd_id'],
    skip_matched_step = true,
    tags = ['t24']
) }}

/*
========================================================================
AS OF DATE MODEL DESCRIPTION
========================================================================
  - Model nay sinh bang lich business day tu ref_holiday.
  - Output gom cac flag dau/cuoi ky va ngay lam viec gan nhat/tiep theo
    de phuc vu snapshot/PIT trong Business Vault.
  - target_date duoc dung de loc du lieu holiday cua ngay snapshot.
========================================================================
*/

WITH ref_holiday_src AS (

    SELECT
        ref_holiday_hashkey,
        year AS hol_year,
        source_event_date,
        record_source,
        load_timestamp,
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
    FROM {{ ref('ref_holiday') }}

),

month_unpivot AS (

    SELECT ref_holiday_hashkey, hol_year, source_event_date, record_source, load_timestamp, '01' AS month_no, t_mth_01_table AS t_mth_table FROM ref_holiday_src
    UNION ALL
    SELECT ref_holiday_hashkey, hol_year, source_event_date, record_source, load_timestamp, '02', t_mth_02_table FROM ref_holiday_src
    UNION ALL
    SELECT ref_holiday_hashkey, hol_year, source_event_date, record_source, load_timestamp, '03', t_mth_03_table FROM ref_holiday_src
    UNION ALL
    SELECT ref_holiday_hashkey, hol_year, source_event_date, record_source, load_timestamp, '04', t_mth_04_table FROM ref_holiday_src
    UNION ALL
    SELECT ref_holiday_hashkey, hol_year, source_event_date, record_source, load_timestamp, '05', t_mth_05_table FROM ref_holiday_src
    UNION ALL
    SELECT ref_holiday_hashkey, hol_year, source_event_date, record_source, load_timestamp, '06', t_mth_06_table FROM ref_holiday_src
    UNION ALL
    SELECT ref_holiday_hashkey, hol_year, source_event_date, record_source, load_timestamp, '07', t_mth_07_table FROM ref_holiday_src
    UNION ALL
    SELECT ref_holiday_hashkey, hol_year, source_event_date, record_source, load_timestamp, '08', t_mth_08_table FROM ref_holiday_src
    UNION ALL
    SELECT ref_holiday_hashkey, hol_year, source_event_date, record_source, load_timestamp, '09', t_mth_09_table FROM ref_holiday_src
    UNION ALL
    SELECT ref_holiday_hashkey, hol_year, source_event_date, record_source, load_timestamp, '10', t_mth_10_table FROM ref_holiday_src
    UNION ALL
    SELECT ref_holiday_hashkey, hol_year, source_event_date, record_source, load_timestamp, '11', t_mth_11_table FROM ref_holiday_src
    UNION ALL
    SELECT ref_holiday_hashkey, hol_year, source_event_date, record_source, load_timestamp, '12', t_mth_12_table FROM ref_holiday_src

),

day_expand AS (

    SELECT
        ref_holiday_hashkey,
        hol_year,
        source_event_date,
        record_source,
        load_timestamp,
        month_no,
        t_mth_table,
        pos AS day_no,
        SUBSTR(t_mth_table, pos, 1) AS day_char,
        CONCAT(hol_year, month_no, LPAD(CAST(pos AS STRING), 2, '0')) AS msr_prd_id
    FROM month_unpivot
    LATERAL VIEW EXPLODE(SEQUENCE(1, LENGTH(t_mth_table))) s AS pos

),

valid_day AS (

    SELECT
        ref_holiday_hashkey,
        CAST(msr_prd_id AS STRING) AS msr_prd_id,
        CAST(SUBSTR(msr_prd_id, 1, 4) AS INT) AS cdr_yr,
        CAST(
            CASE
                WHEN CAST(SUBSTR(msr_prd_id, 5, 2) AS INT) IN (1, 2, 3) THEN 1
                WHEN CAST(SUBSTR(msr_prd_id, 5, 2) AS INT) IN (4, 5, 6) THEN 2
                WHEN CAST(SUBSTR(msr_prd_id, 5, 2) AS INT) IN (7, 8, 9) THEN 3
                ELSE 4
            END AS INT
        ) AS cdr_qtr,
        CAST(DAYOFWEEK(TO_DATE(msr_prd_id, 'yyyyMMdd')) AS INT) AS day_of_wk,
        TO_DATE(msr_prd_id, 'yyyyMMdd') AS msr_prd_dt,
        CAST(CASE WHEN day_char = 'W' THEN 1 ELSE 0 END AS INT) AS bsn_day_f,
        CAST(CASE WHEN day_char = 'H' THEN 1 ELSE 0 END AS INT) AS pblc_hol_f,
        hol_year,
        month_no,
        day_no,
        day_char,
        source_event_date,
        record_source,
        load_timestamp
    FROM day_expand
    WHERE day_char <> 'X'

),

month_flag AS (

    SELECT
        *,
        MIN(CASE WHEN bsn_day_f = 1 THEN day_no END) OVER (
            PARTITION BY hol_year, month_no
        ) AS first_w_day_no,
        MAX(CASE WHEN bsn_day_f = 1 THEN day_no END) OVER (
            PARTITION BY hol_year, month_no
        ) AS last_w_day_no
    FROM valid_day

),

year_flag AS (

    SELECT
        *,
        MIN(CASE WHEN bsn_day_f = 1 THEN msr_prd_id END) OVER (
            PARTITION BY hol_year
        ) AS first_w_yr_id,
        MAX(CASE WHEN bsn_day_f = 1 THEN msr_prd_id END) OVER (
            PARTITION BY hol_year
        ) AS last_w_yr_id
    FROM month_flag

),

final_base AS (

    SELECT
        ref_holiday_hashkey,
        msr_prd_id,
        cdr_yr,
        cdr_qtr,
        day_of_wk,
        msr_prd_dt,
        bsn_day_f,
        pblc_hol_f,
        CAST(CASE WHEN bsn_day_f = 1 AND day_no = last_w_day_no THEN 1 ELSE 0 END AS INT) AS last_bsn_day_f,
        CAST(CASE WHEN bsn_day_f = 1 AND day_no = first_w_day_no THEN 1 ELSE 0 END AS INT) AS is_w_bom,
        CAST(CASE WHEN bsn_day_f = 1 AND day_no = last_w_day_no THEN 1 ELSE 0 END AS INT) AS is_w_eom,
        CAST(CASE WHEN bsn_day_f = 1 AND month_no = '01' AND msr_prd_id = first_w_yr_id THEN 1 ELSE 0 END AS INT) AS is_w_boy,
        CAST(CASE WHEN bsn_day_f = 1 AND month_no = '12' AND msr_prd_id = last_w_yr_id THEN 1 ELSE 0 END AS INT) AS is_w_eoy,
        hol_year,
        source_event_date,
        record_source,
        load_timestamp
    FROM year_flag

),

final_with_next_last AS (

    SELECT
        *,
        MIN(CASE WHEN bsn_day_f = 1 THEN msr_prd_id END) OVER (
            ORDER BY msr_prd_id
            ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING
        ) AS next_wk_id,
        MAX(CASE WHEN bsn_day_f = 1 THEN msr_prd_id END) OVER (
            ORDER BY msr_prd_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS last_wk_id
    FROM final_base

)

SELECT
    ref_holiday_hashkey,
    msr_prd_id,
    cdr_yr,
    cdr_qtr,
    day_of_wk,
    msr_prd_dt,
    bsn_day_f,
    pblc_hol_f,
    last_bsn_day_f,
    next_wk_id,
    last_wk_id,
    TO_DATE(CAST(next_wk_id AS STRING), 'yyyyMMdd') AS next_wk_dt,
    TO_DATE(CAST(last_wk_id AS STRING), 'yyyyMMdd') AS last_wk_dt,
    is_w_bom,
    is_w_eom,
    is_w_boy,
    is_w_eoy,
    source_event_date,
    record_source,
    load_timestamp
FROM final_with_next_last
