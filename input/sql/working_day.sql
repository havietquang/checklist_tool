USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

CREATE OR REPLACE TABLE working_day AS
WITH
v_from_dt AS (
    SELECT
        D.msr_prd_id                                                              AS DATA_DT,
        DATE_FORMAT(
            MAX(TO_DATE(CAST(B.msr_prd_id AS STRING), 'yyyyMMdd')) + INTERVAL 1 DAY,
            'yyyyMMdd'
        )                                                                         AS FROM_DT,
        MAX(TO_DATE(CAST(B.msr_prd_id AS STRING), 'yyyyMMdd')) + INTERVAL 1 DAY  AS FROM_DATE_DT
    FROM IDENTIFIER(:cleaned || '.business_vault.calendar') D
    LEFT JOIN IDENTIFIER(:cleaned || '.business_vault.calendar') B
        ON  D.msr_prd_id > B.msr_prd_id
        AND B.bsn_day_f = 1
    WHERE D.bsn_day_f = 1
    GROUP BY D.msr_prd_id
),
v_end_dt AS (
    SELECT
        D.msr_prd_id                                                              AS DATA_DT,
        DATE_FORMAT(
            MIN(TO_DATE(CAST(E.msr_prd_id AS STRING), 'yyyyMMdd')) - INTERVAL 1 DAY,
            'yyyyMMdd'
        )                                                                         AS END_DT,
        MIN(TO_DATE(CAST(E.msr_prd_id AS STRING), 'yyyyMMdd')) - INTERVAL 1 DAY  AS END_DATE_DT
    FROM IDENTIFIER(:cleaned || '.business_vault.calendar') D
    LEFT JOIN IDENTIFIER(:cleaned || '.business_vault.calendar') E
        ON  D.msr_prd_id < E.msr_prd_id
        AND E.bsn_day_f = 1
    WHERE D.bsn_day_f = 1
    GROUP BY D.msr_prd_id
)
SELECT
    E.DATA_DT,
    TO_DATE(
        CASE
            WHEN SUBSTR(B.FROM_DT, 1, 6) < SUBSTR(CAST(B.DATA_DT AS STRING), 1, 6)
              OR SUBSTR(B.FROM_DT, 7, 2) = '01'
            THEN CONCAT(SUBSTR(CAST(B.DATA_DT AS STRING), 1, 6), '01')
            ELSE CAST(B.DATA_DT AS STRING)
        END, 'yyyyMMdd'
    )                                                                             AS FROM_DATE_DT,
    CASE
        WHEN SUBSTR(B.FROM_DT, 1, 6) < SUBSTR(CAST(B.DATA_DT AS STRING), 1, 6)
          OR SUBSTR(B.FROM_DT, 7, 2) = '01'
        THEN CONCAT(SUBSTR(CAST(B.DATA_DT AS STRING), 1, 6), '01')
        ELSE CAST(B.DATA_DT AS STRING)
    END                                                                           AS FROM_DT,
    CASE
        WHEN SUBSTR(E.END_DT, 1, 6) > SUBSTR(CAST(E.DATA_DT AS STRING), 1, 6)
        THEN DATE_FORMAT(
                TO_DATE(CONCAT(SUBSTR(E.END_DT, 1, 6), '01'), 'yyyyMMdd') - INTERVAL 1 DAY,
                'yyyyMMdd'
             )
        ELSE E.END_DT
    END                                                                           AS END_DT,
    CASE
        WHEN SUBSTR(E.END_DT, 1, 6) > SUBSTR(CAST(E.DATA_DT AS STRING), 1, 6)
        THEN TO_DATE(CONCAT(SUBSTR(E.END_DT, 1, 6), '01'), 'yyyyMMdd') - INTERVAL 1 DAY
        ELSE E.END_DATE_DT
    END                                                                           AS END_DATE_DT,
    CONCAT(SUBSTR(CAST(E.DATA_DT AS STRING), 1, 6), '01')                        AS BEGIN_OF_MONTH,
    TO_DATE(CONCAT(SUBSTR(CAST(E.DATA_DT AS STRING), 1, 6), '01'), 'yyyyMMdd')   AS BEGIN_OF_MONTH_DATE
FROM v_from_dt B
JOIN v_end_dt E ON B.DATA_DT = E.DATA_DT;
