-- Object   : V_CDR_AMT
-- Workbook : 003. OCB_GOLD_TCKH_V_CDR_AMT_QUANG.xlsx
-- Sheet    : Script SQL
-- PIC      : QUANG
-- Nguon    : tai lieu mapping (input/mapping), KHONG phai code trong src/

USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

CREATE OR REPLACE VIEW v_cdr_amt AS
SELECT
    A.DATA_DATE,
    A.AR_ID,
    COALESCE(SUM(A.AMT_DEC), 0)         AS CDR_AMT_DEC,      -- tong AMT_FCY am
    COALESCE(SUM(A.AMT_EQ_DEC), 0)      AS CDR_AMT_EQ_DEC,   -- tong AMT_LCY am
    COALESCE(SUM(A.AMT_INCR), 0)        AS CDR_AMT_INCR,     -- tong AMT_FCY duong
    COALESCE(SUM(A.AMT_EQ_INCR), 0)     AS CDR_AMT_EQ_INCR   -- tong AMT_LCY duong
FROM (
    SELECT
        DATA_DATE,
        PST_ENTR_ID,
        AR_ID,
        CASE WHEN AMT    < 0 THEN AMT    ELSE 0 END AS AMT_DEC,
        CASE WHEN AMT_EQ < 0 THEN AMT_EQ ELSE 0 END AS AMT_EQ_DEC,
        CASE WHEN AMT    > 0 THEN AMT    ELSE 0 END AS AMT_INCR,
        CASE WHEN AMT_EQ > 0 THEN AMT_EQ ELSE 0 END AS AMT_EQ_INCR
    FROM V_ENTRY_STMT_QUYMO
) A
GROUP BY A.DATA_DATE, A.AR_ID;