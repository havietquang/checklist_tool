-- Object   : V_PLA_NIM_UPL
-- Workbook : 017. OCB_GOLD_TCKH_V_PLA_NIM_UPL_QUANG.xlsx
-- Sheet    : Script SQL
-- PIC      : QUANG
-- Nguon    : tai lieu mapping (input/mapping), KHONG phai code trong src/

USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

CREATE OR REPLACE VIEW v_pla_nim_upl AS
SELECT
    A.CDR_DT_ID, A.DATA_DATE, A.GL, A.KPI_LV1, A.KPI_LV2,
    A.CUSTGROUP_NAME, A.CUSTGROUP, A.BRANCH_CODE,
    A.NIM_PLA, A.SDBQ_PLA, A.SDBQLK, A.NIM_BQLK,
    A.LOAN_CLASS, A.LSMV,
    A.NIM_BQLK * A.SDBQLK AS THU_THUAN_LAI
FROM PLA_NIM_UPL A;