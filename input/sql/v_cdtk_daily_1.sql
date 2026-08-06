USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

CREATE OR REPLACE VIEW v_cdtk_daily_1 AS
SELECT
    Ccy,
    Account_ID,
    SubBranch_ID,
    NAME AS Account_Name,
    DDN,
    DDC,
    DSN,
    DSC,
    DCN,
    DCC,
    `Table Names`,
    `File Paths`,
    DATA_DAY,
    DATA_MONTH,
    DATA_YEAR,
    CDR_DT_ID
FROM IDENTIFIER(:curated || '.tckh.tb_cdkt_daily_dtl');
