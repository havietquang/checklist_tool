-- Object   : TB_AR_BCN_DTL
-- Workbook : 045. OCB_GOLD_TCKH_TB_AR_BCN_DTL_QUANG.xlsx
-- Sheet    : Script
-- PIC      : QUANG
-- Nguon    : tai lieu mapping (input/mapping), KHONG phai code trong src/

USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

DELETE FROM tb_ar_bcn_dtl
WHERE  CDR_DT_ID = CAST(:DATADT AS INT);

INSERT INTO tb_ar_bcn_dtl
    (CDR_DT_ID, DATA_DATE, LD_NO, BRANCH_CODE,
     INDUSTRY_LEV5, INDUSTRY_LEV5_DSC, INDUSTRY_LEV4, INDUSTRY_LEV4_DSC,
     PRO_BUNDLE, PROD_MAIN)

WITH
loans_sts_del AS (
    SELECT loans_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sts_hub_loans')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY loans_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
loans_hub AS (
    SELECT loans_hashkey, business_key
    FROM   IDENTIFIER(:cleaned || '.raw_vault.hub_loans')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
      AND  (business_key LIKE 'LD%' OR business_key LIKE 'PDLD%')
    GROUP BY loans_hashkey, business_key
),
loans_active AS (
    SELECT h.loans_hashkey, h.business_key
    FROM      loans_hub h
    LEFT JOIN loans_sts_del x ON x.loans_hashkey = h.loans_hashkey
    WHERE  x.loans_hashkey IS NULL
),

branch_sts_del AS (
    SELECT branch_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sts_hub_branch')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY branch_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
branch_hub AS (
    SELECT branch_hashkey, business_key
    FROM   IDENTIFIER(:cleaned || '.raw_vault.hub_branch')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY branch_hashkey, business_key
),
branch_active AS (
    SELECT h.branch_hashkey, h.business_key
    FROM      branch_hub h
    LEFT JOIN branch_sts_del x ON x.branch_hashkey = h.branch_hashkey
    WHERE  x.branch_hashkey IS NULL
),

lnk_loans_branch AS (
    SELECT loans_hashkey,
           max_by(branch_hashkey, source_event_date) AS branch_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_loans_branch')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY loans_hashkey
),
class_raw AS (
    SELECT loans_hashkey,
           max_by(t_industry_lev3,   source_event_date) AS t_industry_lev3,
           max_by(t_ocb_pro_bundle,  source_event_date) AS t_ocb_pro_bundle,
           max_by(t_ocb_prod_main,   source_event_date) AS t_ocb_prod_main
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_loans_classification')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY loans_hashkey
),
class_latest AS (
    SELECT loans_hashkey, t_industry_lev3, t_ocb_pro_bundle, t_ocb_prod_main,
           CASE WHEN t_industry_lev3 RLIKE '^[A-Za-z]' AND LENGTH(t_industry_lev3) >= 6
                THEN SUBSTR(t_industry_lev3, 1, 6) ELSE NULL END AS industry_lev5_code,
           CASE WHEN t_industry_lev3 RLIKE '^[A-Za-z]' AND LENGTH(t_industry_lev3) >= 5
                THEN SUBSTR(t_industry_lev3, 1, 5) ELSE NULL END AS industry_lev4_code
    FROM class_raw
)
SELECT
    CAST(:DATADT AS INT)                          AS CDR_DT_ID,
    TO_DATE(:DATADT,'yyyyMMdd')                   AS DATA_DATE,
    h.business_key                                AS LD_NO,
    bh.business_key                                AS BRANCH_CODE,
    cl.industry_lev5_code                         AS INDUSTRY_LEV5,
    r5.ref_description                            AS INDUSTRY_LEV5_DSC,
    cl.industry_lev4_code                         AS INDUSTRY_LEV4,
    r4.ref_description                            AS INDUSTRY_LEV4_DSC,
    cl.t_ocb_pro_bundle                           AS PRO_BUNDLE,
    cl.t_ocb_prod_main                            AS PROD_MAIN
FROM loans_active h
LEFT JOIN class_latest      cl ON cl.loans_hashkey = h.loans_hashkey
LEFT JOIN lnk_loans_branch  lb ON lb.loans_hashkey = h.loans_hashkey
LEFT JOIN branch_active     bh ON bh.branch_hashkey = lb.branch_hashkey
LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.ref_t24_ld_economic_sector') r5
       ON r5.ref_code = cl.industry_lev5_code
LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.ref_t24_ld_economic_sector') r4
       ON r4.ref_code = cl.industry_lev4_code
;