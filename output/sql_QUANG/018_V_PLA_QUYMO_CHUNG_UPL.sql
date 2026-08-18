-- Object   : V_PLA_QUYMO_CHUNG_UPL
-- Workbook : 018. OCB_GOLD_TCKH_V_PLA_QUYMO_CHUNG_UPL_QUANG.xlsx
-- Sheet    : Script
-- PIC      : QUANG
-- Nguon    : tai lieu mapping (input/mapping), KHONG phai code trong src/

USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

CREATE OR REPLACE VIEW v_pla_quymo_chung_upl AS
SELECT
      A.TBLE
    , A.DATA_DATE
    , A.GL
    , A.CUSTGROUP
    , A.CUST_GROUP_NAME
    , A.BRANCH_CODE
    , B.BRANCH_NAME
    , B.PRN_BRANCH_CODE
    , B.PRN_BRANCH_NAME
    , A.AMT_EQ_PLA
    , A.AMT_GR_EQ_PLA
    , A.CONTRACT_NO
    , A.START_DATE
    , A.AMT_EQ_AV_PLA
    , A.END_DATE
    , A.NHOM1_PLA
    , A.NHOM2_PLA
    , A.NOXAU_PLA
    , A.UPL_DATE
    , A.CDR_DT_ID
    , NULL AS DRAW_DOWN_PLA
    , NULL AS AMT_EQ_EP_PLA
    , NULL AS NPL_PLA
    , NULL AS NIM_PLA
    , NULL AS SLKH_PLA
FROM PLA_QUYMO_CHUNG_UPL A
LEFT JOIN V_BRANCH_LIST B
    ON A.BRANCH_CODE = B.BRANCH_CODE;