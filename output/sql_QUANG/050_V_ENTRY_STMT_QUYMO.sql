-- Object   : V_ENTRY_STMT_QUYMO
-- Workbook : 050. OCB_GOLD_TCKH_V_ENTRY_STMT_QUYMO_QUANG.xlsx
-- Sheet    : Script SQL
-- PIC      : QUANG
-- Nguon    : tai lieu mapping (input/mapping), KHONG phai code trong src/

USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

CREATE OR REPLACE VIEW v_entry_stmt_quymo AS

WITH W_AR_DIM AS (
    SELECT
        AR_DW_ID,
        AR_DIM_ID
    FROM AR_DIM
)
SELECT
    A.CDR_DT_ID                         AS DATA_DATE,
    D.AR_DIM_ID                         AS AR_ID,
    A.AMT_FCY                           AS AMT,
    A.AMT_LCY                           AS AMT_EQ,
    A.PST_ENTR_ID                       AS PST_ENTR_ID
FROM PST_ENTR_FCT A
LEFT JOIN W_AR_DIM D
    ON A.AR_ID = D.AR_DW_ID
WHERE A.TXN_TP_ID NOT IN ('934', '935', '936', '937')
  AND A.CDR_DT_ID >= 20240701;