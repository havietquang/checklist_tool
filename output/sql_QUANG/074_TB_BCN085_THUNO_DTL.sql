-- Object   : TB_BCN085_THUNO_DTL
-- Workbook : 074. OCB_GOLD_TCKH_TB_BCN085_THUNO_DTL_QUANG.xlsx
-- Sheet    : Script
-- PIC      : QUANG
-- Nguon    : tai lieu mapping (input/mapping), KHONG phai code trong src/

USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

DELETE FROM tb_bcn085_thuno_dtl
WHERE  DATA_DATE = CAST(:DATADT AS STRING);

INSERT INTO tb_bcn085_thuno_dtl
    (ROWNUM, THOAILAIDUTHU, BRANCH_PARENT_CODE, DATA_DATE, TOTAL_AMOUNT_EQ, THU_PS, FULL_NAME,
     BRANCH_CODE, PDDAYS_PR_D_1, PDDAYS_IN_D_1, INTERATE_RATE, CURRENCY, CIF, LN_CLS_D_1,
     THU_PE, LD_NO, TK_THUNO, THU_PHI, BRANCH_PARENT_NAME, NGAY_GIAI_NGAN, THU_IN, BRANCH_NAME,
     LOAN_CLASSIFICATION, CUSTGROUP_DESCRIPTION, TOTAL_AMOUNT, THU_GOC)

WITH

prev_wd AS (
    SELECT CAST(LAST_WK_ID AS INT) AS wd_int
    FROM   IDENTIFIER(:cleaned || '.business_vault.calendar')
    WHERE  MSR_PRD_ID = CAST(:DATADT AS INT)
),

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

customer_sts_del AS (
    SELECT customer_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sts_hub_customer')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY customer_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
customer_hub AS (
    SELECT customer_hashkey, business_key
    FROM   IDENTIFIER(:cleaned || '.raw_vault.hub_customer')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY customer_hashkey, business_key
),
customer_active AS (
    SELECT h.customer_hashkey, h.business_key
    FROM      customer_hub h
    LEFT JOIN customer_sts_del x ON x.customer_hashkey = h.customer_hashkey
    WHERE  x.customer_hashkey IS NULL
),

pd_sts_del AS (
    SELECT s.loans_payment_due_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sts_hub_loans_payment_due') s, prev_wd w
    WHERE  s.source_event_date <= TO_DATE(CAST(w.wd_int AS STRING),'yyyyMMdd')
    GROUP BY s.loans_payment_due_hashkey
    HAVING max_by(s.cdc_status, s.source_event_date) = 'D'
),
pd_hub AS (
    SELECT h.loans_payment_due_hashkey, h.business_key
    FROM   IDENTIFIER(:cleaned || '.raw_vault.hub_loans_payment_due') h, prev_wd w
    WHERE  h.source_event_date <= TO_DATE(CAST(w.wd_int AS STRING),'yyyyMMdd')
    GROUP BY h.loans_payment_due_hashkey, h.business_key
),
pd_active AS (
    SELECT h.loans_payment_due_hashkey, h.business_key
    FROM      pd_hub h
    LEFT JOIN pd_sts_del x ON x.loans_payment_due_hashkey = h.loans_payment_due_hashkey
    WHERE  x.loans_payment_due_hashkey IS NULL
),

stmt_hub AS (
    SELECT stmt_entry_hashkey, business_key
    FROM   IDENTIFIER(:cleaned || '.raw_vault.hub_stmt_entry')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
),
sat_stmt_info AS (
    SELECT stmt_entry_hashkey,
           max_by(t_trans_reference, source_event_date) AS t_trans_reference,
           max_by(t_account_number,  source_event_date) AS t_account_number,
           max_by(t_amount_lcy,      source_event_date) AS t_amount_lcy
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_stmt_entry_information')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY stmt_entry_hashkey
),
sat_stmt_cls AS (
    SELECT stmt_entry_hashkey,
           max_by(t_transaction_code, source_event_date) AS t_transaction_code
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_stmt_entry_classification')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY stmt_entry_hashkey
),
sat_stmt_audit AS (
    SELECT stmt_entry_hashkey,
           max_by(t_record_status, source_event_date) AS t_record_status
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_stmt_entry_audit')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY stmt_entry_hashkey
),

sat_ld_terms AS (
    SELECT loans_hashkey,
           max_by(t_value_date, source_event_date) AS t_value_date
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_loans_terms')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY loans_hashkey
),
sat_cust_info AS (
    SELECT customer_hashkey,
           max_by(name_1, source_event_date) AS name_1,
           max_by(name_2, source_event_date) AS name_2
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_customer_information')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY customer_hashkey
),
sat_cust_cls AS (
    SELECT customer_hashkey,
           max_by(cust_group, source_event_date) AS cust_group,
           max_by(sector,     source_event_date) AS sector
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_customer_classification')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY customer_hashkey
),
ref_sector AS (
    SELECT ref_code,
           max_by(t_sector_group, source_event_date) AS t_sector_group
    FROM   IDENTIFIER(:cleaned || '.raw_vault.ref_t24_sector')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY ref_code
),
sat_pd_over AS (
    SELECT so.loans_payment_due_hashkey,
           max_by(so.t_pay_type,     so.source_event_date) AS t_pay_type,
           max_by(so.t_pay_amt_outs, so.source_event_date) AS t_pay_amt_outs
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_loans_payment_due_overdue') so, prev_wd w
    WHERE  so.source_event_date <= TO_DATE(CAST(w.wd_int AS STRING),'yyyyMMdd')
    GROUP BY so.loans_payment_due_hashkey
),
sat_pd_info AS (
    SELECT si.loans_payment_due_hashkey,
           max_by(si.t_payment_dte_due, si.source_event_date) AS t_payment_dte_due
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_loans_payment_due_information') si, prev_wd w
    WHERE  si.source_event_date <= TO_DATE(CAST(w.wd_int AS STRING),'yyyyMMdd')
    GROUP BY si.loans_payment_due_hashkey
),

lnk_loans_customer AS (
    SELECT loans_hashkey,
           max_by(customer_hashkey, source_event_date) AS customer_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_loans_customer')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY loans_hashkey
),
lnk_loans_branch AS (
    SELECT loans_hashkey,
           max_by(branch_hashkey, source_event_date) AS branch_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_loans_branch')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY loans_hashkey
),

br_raw AS (
    SELECT MACN, MACN_QL, TENCN, TENCN_QL
    FROM   danh_branches
),
cust_name AS (
    SELECT hc.business_key AS cif,
           TRIM(CONCAT(REPLACE(COALESCE(si.name_1,''),'::',' '),
                       REPLACE(COALESCE(si.name_2,''),'::',''))) AS full_name
    FROM      customer_active hc
    LEFT JOIN sat_cust_info   si ON si.customer_hashkey = hc.customer_hashkey
),
cust_class AS (
    SELECT hc.business_key AS cif,
           CASE WHEN sc.cust_group IS NULL
                THEN (CASE WHEN CAST(rs.t_sector_group AS INT) IN (1,4,5) THEN 1 ELSE 2 END)
                ELSE CAST(sc.cust_group AS INT) END AS custgroup
    FROM      customer_active hc
    LEFT JOIN sat_cust_cls    sc ON sc.customer_hashkey = hc.customer_hashkey
    LEFT JOIN ref_sector      rs ON CAST(rs.ref_code AS STRING) = CAST(sc.sector AS STRING)
),
cust_grp AS (
    SELECT k.cif, m.custgroup_description_vn AS custgroup_description
    FROM      cust_class k
    LEFT JOIN customer_custgroup_map m
           ON CAST(m.custgroup AS STRING) = CAST(k.custgroup AS STRING)
),

stmt_all AS (
    SELECT h.business_key AS id, i.t_trans_reference, i.t_account_number, i.t_amount_lcy,
           cl.t_transaction_code, a.t_record_status
    FROM      stmt_hub       h
    LEFT JOIN sat_stmt_info  i  ON i.stmt_entry_hashkey  = h.stmt_entry_hashkey
    LEFT JOIN sat_stmt_cls   cl ON cl.stmt_entry_hashkey = h.stmt_entry_hashkey
    LEFT JOIN sat_stmt_audit a  ON a.stmt_entry_hashkey  = h.stmt_entry_hashkey
),
reve AS (
    SELECT DISTINCT t_trans_reference FROM stmt_all WHERE NVL(t_record_status,'X') = 'REVE'
),
thu AS (
    SELECT
        CASE WHEN SUBSTR(a.t_trans_reference,1,2) = 'LD' THEN SUBSTR(a.t_trans_reference,1,12)
             ELSE SUBSTR(a.t_trans_reference,3,12) END                                     AS ld_no,
        a.t_account_number                                                                 AS tk_thuno,
        CASE WHEN CAST(a.t_transaction_code AS INT) = 450            THEN ABS(NVL(a.t_amount_lcy,0)) ELSE 0 END AS thoailaiduthu,
        CASE WHEN CAST(a.t_transaction_code AS INT) IN (420,423,750) THEN ABS(NVL(a.t_amount_lcy,0)) ELSE 0 END AS thu_goc,
        CASE WHEN CAST(a.t_transaction_code AS INT) IN (424,434,751) THEN ABS(NVL(a.t_amount_lcy,0)) ELSE 0 END AS thu_in,
        CASE WHEN CAST(a.t_transaction_code AS INT) = 752            THEN ABS(NVL(a.t_amount_lcy,0)) ELSE 0 END AS thu_pe,
        CASE WHEN CAST(a.t_transaction_code AS INT) = 753            THEN ABS(NVL(a.t_amount_lcy,0)) ELSE 0 END AS thu_ps,
        CASE WHEN CAST(a.t_transaction_code AS INT) IN (429,430)     THEN ABS(NVL(a.t_amount_lcy,0)) ELSE 0 END AS thu_phi
    FROM      stmt_all a
    LEFT JOIN reve     r ON r.t_trans_reference = a.t_trans_reference
    WHERE  SUBSTR(a.id,1,1) <> 'F'
      AND  a.t_amount_lcy < 0
      AND  SUBSTR(a.t_trans_reference,1,2) IN ('LD','PD')
      AND  CAST(a.t_transaction_code AS INT) IN (450,420,423,750,424,434,751,752,753,429,430)
      AND  r.t_trans_reference IS NULL
),

-- lsl_snap: đọc loan_summary_list DUY NHẤT 1 LẦN (CDR_DT_ID <= :DATADT đã bao trùm cả
-- ngày hiện tại và ngày làm việc trước, vì wd_int luôn < DATADT) - dùng lại cho cả
-- lsl_latest/lsl_same_day/lsl_prev và CTE pastdue_prev bên dưới, thay vì đọc 4 lần.
lsl_snap AS (
    SELECT LD_NO, CDR_DT_ID, CIF, BRANCH_CODE, CURRENCY, LOAN_CLASSIFICATION,
           INTERATE_RATE, TOTAL_AMOUNT, TOTAL_AMOUNT_EQ
    FROM   loan_summary_list
    WHERE  CDR_DT_ID <= CAST(:DATADT AS INT)
),
lsl_latest AS (
    SELECT LD_NO,
           max_by(CIF,                 CDR_DT_ID) AS CIF,
           max_by(BRANCH_CODE,         CDR_DT_ID) AS BRANCH_CODE,
           max_by(CURRENCY,            CDR_DT_ID) AS CURRENCY,
           max_by(LOAN_CLASSIFICATION, CDR_DT_ID) AS LOAN_CLASSIFICATION,
           max_by(INTERATE_RATE,       CDR_DT_ID) AS INTERATE_RATE
    FROM   lsl_snap
    GROUP BY LD_NO
),
lsl_same_day AS (
    SELECT LD_NO,
           max_by(TOTAL_AMOUNT,    CDR_DT_ID) AS TOTAL_AMOUNT,
           max_by(TOTAL_AMOUNT_EQ, CDR_DT_ID) AS TOTAL_AMOUNT_EQ
    FROM   lsl_snap
    WHERE  CDR_DT_ID = CAST(:DATADT AS INT)
    GROUP BY LD_NO
),
lsl_prev AS (
    SELECT l.LD_NO,
           max_by(l.LOAN_CLASSIFICATION, l.CDR_DT_ID) AS ln_cls_d_1
    FROM   lsl_snap l, prev_wd w
    WHERE  l.CDR_DT_ID = w.wd_int
    GROUP BY l.LD_NO
),

pd_raw AS (
    SELECT h.loans_payment_due_hashkey, h.business_key AS id,
           ov.t_pay_type, ov.t_pay_amt_outs, inf.t_payment_dte_due
    FROM      pd_active   h
    LEFT JOIN sat_pd_over ov  ON ov.loans_payment_due_hashkey  = h.loans_payment_due_hashkey
    LEFT JOIN sat_pd_info inf ON inf.loans_payment_due_hashkey = h.loans_payment_due_hashkey
),
pd_l1 AS (
    SELECT id, e1.sub_id,
           e1.pay_type_grp                          AS pay_type_grp,
           SPLIT(t_payment_dte_due,'::')[e1.sub_id] AS dte_due,
           SPLIT(t_pay_amt_outs,'::')[e1.sub_id]    AS amt_outs_grp
    FROM   pd_raw
    LATERAL VIEW POSEXPLODE(SPLIT(t_pay_type,'::')) e1 AS sub_id, pay_type_grp
),
pd_sv AS (
    SELECT id, SUBSTR(id, -12) AS ld_no, sub_id, e2.sv_id,
           e2.t_pay_type                      AS t_pay_type,
           dte_due                            AS t_payment_dte_due,
           SPLIT(amt_outs_grp,'!!')[e2.sv_id] AS t_pay_amt_outs
    FROM   pd_l1
    LATERAL VIEW POSEXPLODE(SPLIT(pay_type_grp,'!!')) e2 AS sv_id, t_pay_type
    WHERE  NVL(CAST(NULLIF(SPLIT(amt_outs_grp,'!!')[e2.sv_id],'') AS DECIMAL(30,4)), 0) <> 0
),
pastdue_prev AS (
    SELECT s.ld_no,
           -- MIN(CASE...ELSE NULL END): conditional MIN có chủ đích - NULL khi không khớp
           -- pay_type để MIN() bỏ qua, không phải thiếu nhánh ELSE.
           COALESCE(DATEDIFF(TO_DATE(CAST(w.wd_int AS STRING),'yyyyMMdd'),
                    MIN(CASE WHEN s.t_pay_type = 'PR'
                             THEN TO_DATE(s.t_payment_dte_due,'yyyyMMdd') ELSE NULL END)), 0) AS max_days_pd_pr,
           COALESCE(DATEDIFF(TO_DATE(CAST(w.wd_int AS STRING),'yyyyMMdd'),
                    MIN(CASE WHEN s.t_pay_type = 'IN'
                             THEN TO_DATE(s.t_payment_dte_due,'yyyyMMdd') ELSE NULL END)), 0) AS max_days_pd_in
    FROM   pd_sv s
           CROSS JOIN prev_wd w
           JOIN ( SELECT DISTINCT l.LD_NO
                  FROM   lsl_snap l, prev_wd w2
                  WHERE  l.CDR_DT_ID = w2.wd_int ) lk ON lk.LD_NO = s.ld_no
    GROUP BY s.ld_no, w.wd_int
),

lt AS (
    SELECT
        a.ld_no                       AS LD_NO,
        a.tk_thuno                    AS TK_THUNO,
        b.CIF                         AS CIF,
        c.MACN_QL                     AS BRANCH_PARENT_CODE,
        c.TENCN_QL                    AS BRANCH_PARENT_NAME,
        c.MACN                        AS BRANCH_CODE,
        c.TENCN                       AS BRANCH_NAME,
        d.full_name                   AS FULL_NAME,
        d3.custgroup_description      AS CUSTGROUP_DESCRIPTION,
        NVL(sd.TOTAL_AMOUNT,0)        AS TOTAL_AMOUNT,
        NVL(sd.TOTAL_AMOUNT_EQ,0)     AS TOTAL_AMOUNT_EQ,
        b.CURRENCY                    AS CURRENCY,
        b.LOAN_CLASSIFICATION         AS LOAN_CLASSIFICATION,
        b.INTERATE_RATE               AS INTERATE_RATE,
        a.thoailaiduthu               AS THOAILAIDUTHU,
        a.thu_goc                     AS THU_GOC,
        a.thu_in                      AS THU_IN,
        a.thu_pe                      AS THU_PE,
        a.thu_ps                      AS THU_PS,
        a.thu_phi                     AS THU_PHI,
        pd.max_days_pd_pr             AS PDDAYS_PR_D_1,
        pd.max_days_pd_in             AS PDDAYS_IN_D_1,
        lp.ln_cls_d_1                 AS LN_CLS_D_1
    FROM      thu          a
    LEFT JOIN lsl_latest   b  ON b.LD_NO  = a.ld_no
    LEFT JOIN lsl_same_day sd ON sd.LD_NO = a.ld_no
    LEFT JOIN br_raw       c  ON CAST(c.MACN AS STRING) = CAST(b.BRANCH_CODE AS STRING)
    LEFT JOIN cust_name    d  ON CAST(d.cif  AS STRING) = CAST(b.CIF AS STRING)
    LEFT JOIN cust_grp     d3 ON CAST(d3.cif AS STRING) = CAST(b.CIF AS STRING)
    LEFT JOIN pastdue_prev pd ON pd.ld_no = a.ld_no
    LEFT JOIN lsl_prev     lp ON lp.LD_NO = a.ld_no
),

ld AS (
    SELECT h.business_key   AS id,
           hc.business_key  AS t_customer_id,
           hb.business_key  AS t_co_code,
           tm.t_value_date
    FROM      loans_active       h
    LEFT JOIN lnk_loans_customer lc ON lc.loans_hashkey    = h.loans_hashkey
    LEFT JOIN customer_active    hc ON hc.customer_hashkey = lc.customer_hashkey
    LEFT JOIN lnk_loans_branch   lb ON lb.loans_hashkey    = h.loans_hashkey
    LEFT JOIN branch_active      hb ON hb.branch_hashkey   = lb.branch_hashkey
    LEFT JOIN sat_ld_terms       tm ON tm.loans_hashkey    = h.loans_hashkey
),

bcn085 AS (
    SELECT
        TO_DATE(:DATADT,'yyyyMMdd')                                  AS DATA_DATE,
        COALESCE(A.CIF,                   B.t_customer_id)           AS MA_KH,
        COALESCE(A.BRANCH_PARENT_CODE,    BR.MACN_QL)                AS MACN_QL,
        COALESCE(A.BRANCH_PARENT_NAME,    BR.TENCN_QL)               AS TENCN_QL,
        COALESCE(A.BRANCH_CODE,           B.t_co_code)               AS MACN,
        COALESCE(A.BRANCH_NAME,           BR.TENCN)                  AS TENCN,
        COALESCE(A.FULL_NAME,             CCN.full_name)             AS TEN_KHACH_HANG,
        COALESCE(A.CUSTGROUP_DESCRIPTION, CCG.custgroup_description) AS TEN_KHOI_PHAN_KHUC,
        A.LD_NO,
        A.TK_THUNO                                                   AS TK_THUNO,
        A.TOTAL_AMOUNT                                               AS DU_NO_NGUYEN_TE,
        A.TOTAL_AMOUNT_EQ                                            AS DU_NO_QUY_DOI_VND,
        A.CURRENCY                                                   AS MA_TIEN_TE,
        A.LOAN_CLASSIFICATION                                        AS NHOM_NO,
        A.INTERATE_RATE                                              AS LAI_SUAT,
        A.THOAILAIDUTHU, A.THU_GOC, A.THU_IN, A.THU_PE, A.THU_PS, A.THU_PHI,
        A.PDDAYS_PR_D_1                                              AS PR_DAY,
        A.PDDAYS_IN_D_1                                              AS IN_DAY,
        A.LN_CLS_D_1                                                 AS NHOM_NO_D_1,
        B.t_value_date                                               AS NGAYGIAINGAN
    FROM      lt A
    LEFT JOIN ld      B   ON CAST(B.id     AS STRING) = CAST(A.LD_NO AS STRING)
    LEFT JOIN br_raw  BR  ON CAST(BR.MACN  AS STRING) = CAST(B.t_co_code AS STRING)
    LEFT JOIN cust_name CCN ON CAST(CCN.cif AS STRING) = CAST(B.t_customer_id AS STRING)
    LEFT JOIN cust_grp  CCG ON CAST(CCG.cif AS STRING) = CAST(B.t_customer_id AS STRING)
)

SELECT
    -- ROWNUM: cột kỹ thuật đánh số thứ tự dòng theo DATA_DATE (giữ nguyên hành vi code cũ),
    -- KHÔNG phải pattern "lấy bản ghi mới nhất" nên không thay được bằng MAX_BY.
    ROW_NUMBER() OVER (ORDER BY DATA_DATE)      AS ROWNUM,
    THOAILAIDUTHU                               AS THOAILAIDUTHU,
    MACN_QL                                     AS BRANCH_PARENT_CODE,
    DATE_FORMAT(DATA_DATE,'yyyyMMdd')           AS DATA_DATE,
    DU_NO_QUY_DOI_VND                           AS TOTAL_AMOUNT_EQ,
    THU_PS                                      AS THU_PS,
    TEN_KHACH_HANG                              AS FULL_NAME,
    MACN                                        AS BRANCH_CODE,
    PR_DAY                                      AS PDDAYS_PR_D_1,
    IN_DAY                                      AS PDDAYS_IN_D_1,
    LAI_SUAT                                    AS INTERATE_RATE,
    MA_TIEN_TE                                  AS CURRENCY,
    MA_KH                                       AS CIF,
    NHOM_NO_D_1                                 AS LN_CLS_D_1,
    THU_PE                                      AS THU_PE,
    LD_NO                                       AS LD_NO,
    TK_THUNO                                    AS TK_THUNO,
    THU_PHI                                     AS THU_PHI,
    TENCN_QL                                    AS BRANCH_PARENT_NAME,
    NGAYGIAINGAN                                AS NGAY_GIAI_NGAN,
    THU_IN                                      AS THU_IN,
    TENCN                                       AS BRANCH_NAME,
    CAST(NHOM_NO AS DECIMAL(1,0))               AS LOAN_CLASSIFICATION,
    TEN_KHOI_PHAN_KHUC                          AS CUSTGROUP_DESCRIPTION,
    DU_NO_NGUYEN_TE                             AS TOTAL_AMOUNT,
    THU_GOC                                     AS THU_GOC
FROM   bcn085
;