-- Object   : V_BCN_THUNO_1
-- Workbook : 047. OCB_GOLD_TCKH_V_BCN_THUNO_1_QUANG.xlsx
-- Sheet    : Script SQL
-- PIC      : QUANG
-- Nguon    : tai lieu mapping (input/mapping), KHONG phai code trong src/

USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

CREATE OR REPLACE VIEW v_bcn_thuno_1 AS

WITH

-- ── BCN085: chi tiết thu nợ, enrich CUST_GROUP từ t24_customer theo DATA_DATE + CIF
bcn085 AS (
    SELECT
        a.DATA_DATE,
        eomonth(dateadd(month, -1, eomonth(a.DATA_DATE)))  AS BOM,
        a.CIF,
        a.FULL_NAME,
        a.BRANCH_CODE,
        a.BRANCH_NAME,
        a.BRANCH_PARENT_CODE,
        a.BRANCH_PARENT_NAME,
        a.LD_NO,
        a.LOAN_CLASSIFICATION,
        REPLACE(a.TK_THUNO, '''', '')                      AS TK_THUNO,
        a.THU_GOC, a.THU_IN, a.THU_PE, a.THU_PS, a.THU_PHI,
        a.LN_CLS_D_1,
        a.INTERATE_RATE,
        ISNULL(a.PDDAYS_IN_D_1, 0)                          AS PDDAYS_IN_D_1,
        ISNULL(a.PDDAYS_PR_D_1, 0)                          AS PDDAYS_PR_D_1,
        a.THOAILAIDUTHU,
        a.CUSTGROUP_DESCRIPTION,
        b.T_CUST_GROUP                                      AS T_CUST_GROUP
    FROM      tb_bcn085_thuno_dtl a
    LEFT JOIN t24_customer b
           ON a.DATA_DATE = b.DATA_DATE
          AND a.CIF       = b.ID
    WHERE a.DATA_DATE >= '20260101' AND a.DATA_DATE <= '20991231'
),

-- ── Sao kê BCN085 kèm nhóm nợ CIC (từ d_cic_dungky_final)
saoke AS (
    SELECT
        s.DATA_DATE,
        eomonth(s.DATA_DATE)                     AS EOM,
        s.CIF,
        s.FULL_NAME,
        s.BRANCH_CODE,
        s.LD_NO,
        s.NHOM_NO_QUANTRI_V2,
        cic.NN_TT31_KEOTHEO_CIC                  AS NHOM_NO_cic,
        s.NHOM_NO_CANDOI,
        s.NHOM_NO_THEO_SNQH,
        s.SO_NGAY_QH_GOC,
        s.SO_NGAY_QH_LAI,
        s.DUNO_NTE,
        s.DUNO_QUYVND
    FROM      tb_saoke_bcn085 s
    LEFT JOIN d_cic_dungky_final cic
           ON s.CIF       = cic.CIF
          AND s.DATA_DATE = cic.NGAY
          AND s.LD_NO     = cic.SO_HOP_DONG
    WHERE s.DATA_DATE >= 20251231
),

-- ── Nhóm nợ CIC theo CIF (gộp theo mọi LD_NO), lấy giá trị lớn nhất
nhomno_cic AS (
    SELECT
        s.DATA_DATE,
        eomonth(s.DATA_DATE)                       AS EOM,
        s.CIF,
        MAX(cic.NN_TT31_KEOTHEO_CIC)               AS NHOM_NO_cic
    FROM      tb_saoke_bcn085 s
    LEFT JOIN d_cic_dungky_final cic
           ON s.CIF       = cic.CIF
          AND s.DATA_DATE = cic.NGAY
          AND s.LD_NO     = cic.SO_HOP_DONG
    WHERE s.DATA_DATE >= 20251231
    GROUP BY s.DATA_DATE, eomonth(s.DATA_DATE), s.CIF
),

-- ── Sao kê đầu năm (mốc 20251231), dùng làm số dư/nhóm nợ đầu kỳ
saoke_dau_nam AS (
    SELECT
        DATA_DATE, eomonth(DATA_DATE) AS EOM, CIF, FULL_NAME, BRANCH_CODE, LD_NO,
        NHOM_NO_QUANTRI_V2, NHOM_NO_cic, NHOM_NO_CANDOI, NHOM_NO_THEO_SNQH,
        SO_NGAY_QH_GOC, SO_NGAY_QH_LAI, DUNO_NTE, DUNO_QUYVND
    FROM tb_saoke_bcn085
    WHERE DATA_DATE = 20251231
)

SELECT
    a.DATA_DATE,
    a.DATA_DATE                                                 AS CDR_DT_ID,
    a.BOM,
    a.CIF,
    a.FULL_NAME,
    a.BRANCH_CODE,
    a.BRANCH_NAME,
    a.BRANCH_PARENT_CODE,
    a.BRANCH_PARENT_NAME,
    a.LD_NO,
    a.LOAN_CLASSIFICATION,
    a.TK_THUNO,
    a.THU_GOC,
    a.THU_IN,
    a.THU_PE,
    a.THU_PS,
    a.THU_PHI,
    a.LN_CLS_D_1,
    a.INTERATE_RATE,
    a.PDDAYS_IN_D_1,
    a.PDDAYS_PR_D_1,
    a.THOAILAIDUTHU,
    b.NHOM_NO_QUANTRI_V2,
    ISNULL(cic.NHOM_NO_cic, b.NHOM_NO_cic)                      AS NHOM_NO_CIC,
    b.NHOM_NO_CANDOI,
    b.NHOM_NO_THEO_SNQH,
    b.SO_NGAY_QH_GOC,
    b.SO_NGAY_QH_LAI,
    b.DUNO_NTE,
    b.DUNO_QUYVND,
    a.CUSTGROUP_DESCRIPTION,
    a.T_CUST_GROUP,
    dau_nam.NHOM_NO_THEO_SNQH                                   AS NHOM_NO_THEO_SNQH_DAUNAM,
    dau_nam.NHOM_NO_cic                                         AS NHOM_NO_CIC_DAU_NAM,
    dau_nam.NHOM_NO_QUANTRI_V2                                  AS NHOM_NO_QUANTRI_V2_DAUNAM
FROM      bcn085 a
LEFT JOIN saoke          b       ON a.LD_NO = b.LD_NO AND a.BOM = b.EOM
LEFT JOIN nhomno_cic     cic     ON a.CIF   = cic.CIF AND a.BOM = cic.EOM
LEFT JOIN saoke_dau_nam  dau_nam ON a.LD_NO = dau_nam.LD_NO
WHERE a.DATA_DATE >= '20251231' AND a.DATA_DATE <= '20261231';