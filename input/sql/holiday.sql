USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

CREATE OR REPLACE TABLE holiday AS
SELECT
    TO_DATE(CAST(MAX(W.msr_prd_id) AS STRING), 'yyyyMMdd')   AS DATA_DATE_DT,
    TO_DATE(CAST(D.msr_prd_id AS STRING), 'yyyyMMdd')        AS HOLIDAY_DATE_DT,
    MAX(W.msr_prd_id)                                         AS DATA_DT,
    D.msr_prd_id                                              AS HOLIDAY_DT
FROM IDENTIFIER(:cleaned || '.business_vault.calendar') D
LEFT JOIN IDENTIFIER(:cleaned || '.business_vault.calendar') W
    ON  D.msr_prd_id > W.msr_prd_id
    AND W.bsn_day_f = 1
WHERE D.bsn_day_f = 0
GROUP BY D.msr_prd_id;
