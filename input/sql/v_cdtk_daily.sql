USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

CREATE OR REPLACE VIEW v_cdtk_daily AS
WITH w_data_date_full AS (
    SELECT
        HOLIDAY_DT,
        DATA_DT,
        HOLIDAY_DATE_DT,
        DATA_DATE_DT,
        'HOLIDAY' AS BANG
    FROM holiday
    UNION ALL
    SELECT
        DATA_DT AS HOLIDAY_DT,
        DATA_DT,
        TO_DATE(CAST(DATA_DT AS STRING), 'yyyyMMdd') AS HOLIDAY_DATE_DT,
        TO_DATE(CAST(DATA_DT AS STRING), 'yyyyMMdd') AS DATA_DATE_DT,
        'WORKING' AS BANG
    FROM working_day
)
SELECT
    A.Ccy,
    A.Account_ID,
    A.SubBranch_ID,
    A.Account_Name,
    A.DDN,
    A.DDC,
    A.DSN,
    A.DSC,
    A.DCN,
    A.DCC,
    A.`Table Names`,
    A.`File Paths`,
    A.DATA_DAY,
    A.DATA_MONTH,
    A.DATA_YEAR,
    A.CDR_DT_ID,
    B.HOLIDAY_DATE_DT AS DATA_DATE
FROM v_cdtk_daily_1 A
LEFT JOIN w_data_date_full B
    ON A.CDR_DT_ID = B.DATA_DT;
