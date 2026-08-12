USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

-- ── V_BCN_THUNO: v_bcn_thuno_1 + GL/LOAN_CLASS_BY_GL (tb_ar_dtl_daily) + PRO_BUNDLE/PROD_MAIN (tb_ar_bcn_dtl)
CREATE OR REPLACE VIEW v_bcn_thuno AS

SELECT
    bcn.DATA_DATE,
    bcn.CDR_DT_ID,
    LEFT(bcn.DATA_DATE, 6)                                    AS THANG,
    bcn.BOM,
    bcn.CIF                                                   AS CIF,
    bcn.FULL_NAME,
    bcn.BRANCH_CODE,
    bcn.BRANCH_NAME,
    bcn.BRANCH_PARENT_CODE,
    bcn.BRANCH_PARENT_NAME,
    bcn.LD_NO,
    bcn.LOAN_CLASSIFICATION,
    bcn.TK_THUNO,
    bcn.THU_GOC,
    bcn.THU_IN,
    bcn.THU_PE,
    bcn.THU_PS,
    bcn.THU_PHI,
    bcn.LN_CLS_D_1,
    bcn.INTERATE_RATE,
    bcn.PDDAYS_IN_D_1,
    bcn.PDDAYS_PR_D_1,
    bcn.THOAILAIDUTHU,
    bcn.NHOM_NO_QUANTRI_V2,
    bcn.NHOM_NO_CIC,
    bcn.NHOM_NO_CANDOI,
    bcn.NHOM_NO_THEO_SNQH,
    bcn.SO_NGAY_QH_GOC,
    bcn.SO_NGAY_QH_LAI,
    bcn.DUNO_NTE,
    bcn.DUNO_QUYVND,
    ar.GL,
    ar.LOAN_CLASS_BY_GL,
    COALESCE(bcn.CUSTGROUP_DESCRIPTION, ar.CUST_GROUP_NAME)  AS CUSTGROUP_DESCRIPTION,
    COALESCE(bcn.T_CUST_GROUP, ar.CUSTGROUP)                 AS CUSTGROUP,
    bcn.NHOM_NO_THEO_SNQH_DAUNAM,
    bcn.NHOM_NO_CIC_DAU_NAM,
    bcn.NHOM_NO_QUANTRI_V2_DAUNAM,
    COALESCE(bundle.PRO_BUNDLE, '')                           AS PRO_BUNDLE,
    COALESCE(bundle.PROD_MAIN, '')                            AS PROD_MAIN
FROM      v_bcn_thuno_1 bcn
LEFT JOIN (
    SELECT DISTINCT
           CDR_DT_ID, CONTRACT_NO, LOAN_CLASS_BY_GL,
           CASE WHEN GL = '9711' THEN '9711' ELSE '' END AS GL,
           CUSTGROUP, CUST_GROUP_NAME
    FROM   tb_ar_dtl_daily
) ar ON bcn.DATA_DATE           = ar.CDR_DT_ID
    AND bcn.LD_NO               = ar.CONTRACT_NO
    AND bcn.LOAN_CLASSIFICATION = ar.LOAN_CLASS_BY_GL
LEFT JOIN tb_ar_bcn_dtl bundle
       ON bcn.CDR_DT_ID = bundle.CDR_DT_ID
      AND bcn.LD_NO     = bundle.LD_NO;