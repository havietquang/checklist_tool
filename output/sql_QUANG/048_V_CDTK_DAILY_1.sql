-- Object   : V_CDTK_DAILY_1
-- Workbook : 048. OCB_GOLD_TCKH_V_CDTK_DAILY_1_QUANG.xlsx
-- Sheet    : Script SQL
-- PIC      : QUANG
-- Nguon    : tai lieu mapping (input/mapping), KHONG phai code trong src/

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
    Table_Names,
    File_Paths,
    DATA_DAY,
    DATA_MONTH,
    DATA_YEAR,
    CDR_DT_ID
FROM IDENTIFIER(:curated || '.tckh.tb_cdkt_daily_dtl');