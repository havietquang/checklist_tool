-- Object   : V_PLA_QUYMO_NOXAU_UPL
-- Workbook : 019. OCB_GOLD_TCKH_V_PLA_QUYMO_NOXAU_UPL_QUANG.xlsx
-- Sheet    : Script SQL
-- PIC      : QUANG
-- Nguon    : tai lieu mapping (input/mapping), KHONG phai code trong src/

USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;
CREATE OR REPLACE VIEW v_pla_quymo_noxau_upl AS
SELECT
      A.DATA_DATE
    , A.CUSTGROUP
    , A.CUST_GROUP_NAME
    , A.NO_XAU
    , A.CDR_DT_ID
    , A.GL
    , A.BRANCH_CODE
    , B.BRANCH_NAME
    , B.PRN_BRANCH_CODE
    , B.PRN_BRANCH_NAME
    , A.NX_AMT_EQ_PLA
FROM PLA_QUYMO_NOXAU_UPL A
LEFT JOIN V_BRANCH_LIST B
    ON A.BRANCH_CODE = B.BRANCH_CODE;