USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

DELETE FROM loan_summary_list
WHERE CDR_DT_ID = CAST(:target_date AS INT);

INSERT INTO loan_summary_list (
    CDR_DT_ID, LD_NO, LD_NO_OLD, BDW_SCTR_ID, OFCR_ID, BDW_CST_GRP_ID, AR_ID, OU_ID,
    LINK_REFERENCE, CIF, OCB_PRODUCT_PARTNER_NAME, OCB_PRODUCT_PARTNER_ID, FULL_NAME,
    BRANCH_CODE, BRANCH_NAME, BRANCH_PARENT_CODE, BRANCH_PARENT_NAME, GL, INPUTTER, AUTHORISER,
    FIXED_VARIABLE, LIMIT_REFERENCE_1, LIMIT_REFERENCE_3, LIMIT_DESCRIPTION, CURRENCY,
    LOAN_CLASSIFICATION, VALUE_DATE, MATURE_DATE, DRAW_DOWN_AMT, TOTAL_AMOUNT, TOTAL_AMOUNT_EQ,
    LD_AMOUNT_EQ, PD_AMOUNT_EQ, ACCURAL_AMT_394_EQ, ACCURAL_AMT_94_EQ, PR_DAY, IN_DAY, PE_DAY, PS_DAY,
    PR, IN, PE, PS, TERM, INTERATE_RATE, INTEREST_SPREAD, INT_RATE_TYPE, INTEREST_KEY,
    FREQUENCY, PENALTY_RATE, PENALTY_SPREAD, MAIN_PURPOSE_NO, MAIN_PURPOSE_NAME, INDUSTRY,
    INDUSTRY_DESCRIPTION, INDUSTRY_LEV1, INDUSTRY_LEV2, INDUSTRY_LEV3, INDUSTRY_LEV1_DESC,
    INDUSTRY_LEV2_DESC, INDUSTRY_LEV3_DESC, SECTOR, SECTOR_DESCRIPTION, RATE, RATE_PROVISION,
    PROVISION_AMT, COLLATERAL_AMOUNT, COLLATERAL_TYPE, COLLATERAL_NOMINAL, CATEGORY,
    CATEGORY_DESCRIPTION, LOAN_SUBPRODUCT, LOAN_SUBPRODUCT_DESC, LOAN_METHOD, LOAN_METHOD_DESC,
    CUST_REMARKS, CLASSIFICATION, CUSTGROUP, CUSTGROUP_DESCRIPTION, OVERDUE_STATUS,
    ACCOUNT_OFFICER_ID, ACCOUNT_OFFICER_NAME, LIQUIDATION_MODE, LN_CLASS_MANUAL, EXTEND_SCH,
    EXTENDSCH_DATE, PROMOTION_ID, PROMOTION_NAME, CRT_TM, PPN_TM, INT_RATE_TYPE_DESC,
    INTEREST_KEY_DESC, AC_MIDDLEMAN_ID, AC_MIDDLEMAN_NAME, PROVISION_OUSTANDING,
    NEXT_REPAYMENT_DATE, TOTAL_INTEREST_AMT, NEXT_REPAYMENT_AMT_PR, REPAYMENT_ACCOUNT, INT_LIQ_ACCT,
    PREV_REPAYMENT_DATE, PREV_REPAYMENT_AMT_PR, LD_AMOUNT, NEXT_DATE_IN, NEXT_AMT_IN,
    LAST_DATE_IN, LAST_AMT_IN, IS_COMB, T24_LOAN_CLASS_CIF, T24_LN_CLASS
)
WITH

del_limit AS (
    SELECT limit_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_limit')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY limit_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
del_collateral AS (
    SELECT collateral_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_collateral')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY collateral_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
del_collateral_right AS (
    SELECT collateral_right_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_collateral_right')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY collateral_right_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
del_customer AS (
    SELECT customer_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_customer')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY customer_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
del_acct_officer AS (
    SELECT dept_acct_officer_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_acct_officer')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY dept_acct_officer_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
sts_sched_del AS (
    SELECT loans_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_loans_ld_schedule_define')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),

customer_active AS (
    SELECT hc.customer_hashkey, hc.business_key
    FROM IDENTIFIER(:cleaned || '.raw_vault.hub_customer') hc
    LEFT JOIN del_customer dcu ON dcu.customer_hashkey = hc.customer_hashkey
    WHERE hc.source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
      AND dcu.customer_hashkey IS NULL
    GROUP BY hc.customer_hashkey, hc.business_key
),
cust_cls_cur AS (
    SELECT customer_hashkey,
           max_by(sector, source_event_date)      AS sector,
           max_by(cust_group, source_event_date)  AS cust_group,
           max_by(asset_class, source_event_date) AS asset_class
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_customer_classification')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY customer_hashkey
),
ln_cust_cur AS (
    SELECT loans_hashkey, max_by(customer_hashkey, source_event_date) AS customer_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.link_loans_customer')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_hashkey
),
ofcr_active AS (
    SELECT ho.dept_acct_officer_hashkey, ho.business_key
    FROM IDENTIFIER(:cleaned || '.raw_vault.hub_acct_officer') ho
    LEFT JOIN del_acct_officer dao ON dao.dept_acct_officer_hashkey = ho.dept_acct_officer_hashkey
    WHERE ho.source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
      AND dao.dept_acct_officer_hashkey IS NULL
    GROUP BY ho.dept_acct_officer_hashkey, ho.business_key
),
ofcr_info_cur AS (
    SELECT dept_acct_officer_hashkey, max_by(t_name, source_event_date) AS t_name
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_acct_officer_information')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY dept_acct_officer_hashkey
),
ln_limit_cur AS (
    SELECT loans_hashkey, max_by(limit_hashkey, source_event_date) AS limit_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.link_loans_limit')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_hashkey
),
limit_info_cur AS (
    SELECT limit_hashkey,
           max_by(t_internal_amount, source_event_date)   AS t_internal_amount,
           max_by(t_online_limit_date, source_event_date) AS t_online_limit_date,
           max_by(t_expiry_date, source_event_date)       AS t_expiry_date,
           max_by(t_fixed_variable, source_event_date)    AS t_fixed_variable,
           max_by(t_credit_line, source_event_date)       AS t_credit_line
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_limit_information')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY limit_hashkey
),
pd_over_cur AS (
    SELECT loans_payment_due_hashkey,
           max_by(t_pay_type, source_event_date)     AS t_pay_type,
           max_by(t_pay_amt_outs, source_event_date) AS t_pay_amt_outs,
           max_by(t_penalty_rate, source_event_date) AS t_penalty_rate
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_loans_payment_due_overdue')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_payment_due_hashkey
),
ln_pd_cur AS (
    SELECT loans_payment_due_hashkey, max_by(loans_hashkey, source_event_date) AS loans_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.link_loans_payment_due')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_payment_due_hashkey
),
comb_hub_raw AS (
    SELECT consumer_loan_hashkey, business_key
    FROM IDENTIFIER(:cleaned || '.raw_vault.hub_consumer_loan')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY consumer_loan_hashkey, business_key
),
comb_active AS (
    SELECT h.consumer_loan_hashkey, h.business_key
    FROM comb_hub_raw h
    LEFT JOIN ( SELECT consumer_loan_hashkey
                FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_consumer_loan')
                WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
                GROUP BY consumer_loan_hashkey
                HAVING max_by(cdc_status, source_event_date) = 'D' ) del
           ON del.consumer_loan_hashkey = h.consumer_loan_hashkey
    WHERE del.consumer_loan_hashkey IS NULL
),
coll_rl_cur AS (
    SELECT collateral_right_hashkey,
           max_by(limit_hashkey, source_event_date) AS limit_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.link_collateral_right_limit')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY collateral_right_hashkey
),
coll_cr_cur AS (
    SELECT collateral_right_hashkey,
           max_by(collateral_hashkey, source_event_date) AS collateral_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.link_collateral_collateral_right')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY collateral_right_hashkey
),
coll_info_cur AS (
    SELECT collateral_hashkey,
           max_by(t_currency, source_event_date)        AS t_currency,
           max_by(t_collateral_type, source_event_date) AS t_collateral_type
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_collateral_information')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY collateral_hashkey
),
sched_cur AS (
    SELECT loans_hashkey, t_k_date, t_sch_type, t_cycled_dates, cycled_dates_seq,
           max_by(t_amount, source_event_date)    AS t_amount,
           max_by(t_frequency, source_event_date) AS t_frequency
    FROM IDENTIFIER(:cleaned || '.business_vault.csat_loans_schedule')
    WHERE source_event_date = TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_hashkey, t_k_date, t_sch_type, t_cycled_dates, cycled_dates_seq
),

rt_base AS (
    SELECT
        CDR_DT_ID, AR_ID, AR_NO, OU_ID, SCTR_ID, OFCR_ID, CST_GRP_ID,
        GL, GL_TP_ID, CCY_ID, LN_CL_BY_GL_ID, OPN_DT, MAT_DT,
        BAL_AMT_FCY, BAL_AMT_LCY, BAL_INT_AMT_LCY, OFFBAL_INT_AMT_LCY,
        MX_PD_PR_DYS, MX_PD_INT_DYS, MX_PD_PE_DYS, MX_PD_PS_DYS,
        PD_PR_AMT, PD_INT_AMT, PD_PE_AMT, PD_PS_AMT,
        INT_RATE, T24_LOAN_CLASS_CIF, T24_LN_CLASS
    FROM rt_ar_dtl
    WHERE CDR_DT_ID = CAST(:target_date AS INT)
),

rt AS (
    SELECT
        a.CDR_DT_ID, a.AR_ID, a.AR_NO, a.OU_ID, a.SCTR_ID, a.OFCR_ID, a.CST_GRP_ID,
        a.GL, a.CCY_ID, a.LN_CL_BY_GL_ID, a.OPN_DT, a.MAT_DT,
        a.BAL_AMT_FCY, a.BAL_AMT_LCY, a.BAL_INT_AMT_LCY, a.OFFBAL_INT_AMT_LCY,
        a.MX_PD_PR_DYS, a.MX_PD_INT_DYS, a.MX_PD_PE_DYS, a.MX_PD_PS_DYS,
        a.PD_PR_AMT, a.PD_INT_AMT, a.PD_PE_AMT, a.PD_PS_AMT,
        a.INT_RATE, a.T24_LOAN_CLASS_CIF, a.T24_LN_CLASS
    FROM rt_base a
    WHERE ( a.GL_TP_ID IN ('CHOVAYTT1','CHOVAYTT2','NOVAMC')
         OR ( a.GL_TP_ID IN ('CHOVAYTT1BS','NOXLRR') AND SUBSTR(a.AR_NO,1,2) IN ('LD','PD') ) )
),

ld_hub AS (
    SELECT h.loans_hashkey, h.business_key
    FROM IDENTIFIER(:cleaned || '.raw_vault.hub_loans') h
    LEFT JOIN (
        SELECT loans_hashkey
        FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_loans')
        WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
        GROUP BY loans_hashkey
        HAVING max_by(cdc_status, source_event_date) = 'D'
    ) sts ON sts.loans_hashkey = h.loans_hashkey
    WHERE sts.loans_hashkey IS NULL
      AND h.source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
      AND h.record_source      = 't24__t24_loans_and_deposits'
),
ld_rate AS (
    SELECT loans_hashkey,
           max_by(t_interest_spread, source_event_date) AS t_interest_spread,
           max_by(t_int_rate_type, source_event_date) AS t_int_rate_type,
           max_by(t_interest_key, source_event_date) AS t_interest_key,
           max_by(t_int_key_name, source_event_date) AS t_int_key_name,
           max_by(t_tot_interest_amt, source_event_date) AS t_tot_interest_amt
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_loans_rate')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_hashkey
),
ld_cls AS (
    SELECT loans_hashkey,
           t_category, t_loan_subproduct, t_loan_method, t_industry_lev1,
           t_industry_lev2, t_industry_lev3, t_liquidation_mode, t_extend_sch,
           t_extendsch_date, t_ocb_promotion, t_ocb_pro_partner, t_ld_cust_group,
           t_loan_purpose
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_loans_classification')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY loans_hashkey
                               ORDER BY source_event_date DESC) = 1
),
ld_info AS (
    SELECT loans_hashkey,
           t_limit_reference, t_link_reference, t_legacy_ref, t_drawdown_net_amt,
           t_prin_liq_acct, t_int_liq_acct, t_currency, t_status,
           t_ln_class_manual
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_loans_information')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY loans_hashkey
                               ORDER BY source_event_date DESC) = 1
),
ld_terms AS (
    SELECT loans_hashkey,
           max_by(t_term, source_event_date) AS t_term
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_loans_terms')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_hashkey
),
ld_sys AS (
    SELECT loans_hashkey,
           max_by(t_inputter, source_event_date) AS t_inputter,
           max_by(t_authoriser, source_event_date) AS t_authoriser
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_loans_system')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_hashkey
),
ld_other AS (
    SELECT loans_hashkey,
           max_by(t_cust_remarks, source_event_date) AS t_cust_remarks
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_loans_other')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_hashkey
),
ld_cust AS (
    SELECT l.loans_hashkey, hc.business_key AS t_customer_id, sc.sector AS sctr_code
    FROM ln_cust_cur l
    JOIN customer_active hc ON hc.customer_hashkey = l.customer_hashkey
    LEFT JOIN cust_cls_cur sc ON sc.customer_hashkey = hc.customer_hashkey
),
ld_middleman AS (
    SELECT l.loans_hashkey, si.t_name AS ac_middleman_name, ho.business_key AS ac_middleman_id
    FROM ( SELECT loans_hashkey,
           max_by(dept_acct_officer_hashkey, source_event_date) AS dept_acct_officer_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.link_loans_dept_acct_officer_nvgt')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_hashkey ) l
    JOIN ofcr_active ho ON ho.dept_acct_officer_hashkey = l.dept_acct_officer_hashkey
    LEFT JOIN ofcr_info_cur si ON si.dept_acct_officer_hashkey = ho.dept_acct_officer_hashkey
),
ld_limit AS (
    SELECT l.loans_hashkey, sli.t_fixed_variable, sli.t_credit_line
    FROM ln_limit_cur l
    LEFT JOIN limit_info_cur sli ON sli.limit_hashkey = l.limit_hashkey
    LEFT JOIN del_limit dl ON dl.limit_hashkey = l.limit_hashkey
    WHERE dl.limit_hashkey IS NULL
),
loans AS (
    SELECT
        h.loans_hashkey, h.business_key                                AS ld_id,
        r.t_interest_spread, r.t_int_rate_type, r.t_interest_key,
        r.t_int_key_name, r.t_tot_interest_amt,
        c.t_category, c.t_loan_subproduct, c.t_loan_method,
        c.t_industry_lev1, c.t_industry_lev2, c.t_industry_lev3,
        c.t_liquidation_mode, c.t_extend_sch, c.t_extendsch_date,
        c.t_ocb_promotion, c.t_ocb_pro_partner, c.t_ld_cust_group, c.t_loan_purpose,
        i.t_limit_reference, i.t_link_reference, i.t_legacy_ref,
        i.t_drawdown_net_amt, i.t_prin_liq_acct, i.t_int_liq_acct, i.t_status,
        i.t_ln_class_manual,
        tm.t_term, sy.t_inputter, sy.t_authoriser, ot.t_cust_remarks,
        cu.t_customer_id, cu.sctr_code,
        mm.ac_middleman_id, mm.ac_middleman_name,
        ll.t_fixed_variable, ll.t_credit_line
    FROM ld_hub h
    LEFT JOIN ld_rate  r  ON r.loans_hashkey  = h.loans_hashkey
    LEFT JOIN ld_cls   c  ON c.loans_hashkey  = h.loans_hashkey
    LEFT JOIN ld_info  i  ON i.loans_hashkey  = h.loans_hashkey
    LEFT JOIN ld_terms tm ON tm.loans_hashkey = h.loans_hashkey
    LEFT JOIN ld_sys   sy ON sy.loans_hashkey = h.loans_hashkey
    LEFT JOIN ld_other ot ON ot.loans_hashkey = h.loans_hashkey
    LEFT JOIN ld_cust  cu ON cu.loans_hashkey = h.loans_hashkey
    LEFT JOIN ld_middleman mm ON mm.loans_hashkey = h.loans_hashkey
    LEFT JOIN ld_limit ll ON ll.loans_hashkey = h.loans_hashkey
),

acct_hub AS (
    SELECT h.account_hashkey, h.business_key
    FROM IDENTIFIER(:cleaned || '.raw_vault.hub_account') h
    LEFT JOIN (
        SELECT account_hashkey
        FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_account')
        WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
        GROUP BY account_hashkey
        HAVING max_by(cdc_status, source_event_date) = 'D'
    ) sts ON sts.account_hashkey = h.account_hashkey
    WHERE sts.account_hashkey IS NULL
      AND h.source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
      AND h.record_source      = 't24__t24_account'
),
acct_cls AS (
    SELECT account_hashkey,
           max_by(t_category, source_event_date) AS t_category,
           max_by(t_limit_ref, source_event_date) AS t_limit_ref
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_account_classification')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY account_hashkey
),
acct_cust AS (
    SELECT l.account_hashkey, hc.business_key AS t_customer
    FROM ( SELECT account_hashkey,
           max_by(customer_hashkey, source_event_date) AS customer_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.link_account_customer')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY account_hashkey ) l
    JOIN customer_active hc ON hc.customer_hashkey = l.customer_hashkey
),
lim_info AS (
    SELECT limit_hashkey, t_internal_amount, t_online_limit_date,
           t_expiry_date, t_fixed_variable
    FROM limit_info_cur
),
lim_hub AS (
    SELECT h.limit_hashkey, h.business_key
    FROM IDENTIFIER(:cleaned || '.raw_vault.hub_limit') h
    LEFT JOIN del_limit dl ON dl.limit_hashkey = h.limit_hashkey
    WHERE h.source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
      AND dl.limit_hashkey IS NULL
),
acct_limit_tt03 AS (
    SELECT
        ac.t_customer                                              AS tc_cif,
        acl.t_limit_ref                                            AS tc_limit_ref,
        CAST(ac.t_customer || '.000' || acl.t_limit_ref AS STRING) AS tc_limit_reference_3,
        li.t_internal_amount                                       AS tc_internal_amount,
        li.t_online_limit_date                                     AS tc_online_limit_date,
        li.t_expiry_date                                           AS tc_expiry_date,
        acl.t_category                                             AS tc_category,
        ah.business_key                                            AS tc_account_no,
        1                                                          AS tc_is_acct_limit
    FROM acct_hub ah
    JOIN acct_cls acl ON acl.account_hashkey = ah.account_hashkey
    JOIN acct_cust ac ON ac.account_hashkey  = ah.account_hashkey
    JOIN lim_hub  lh  ON lh.business_key      = ac.t_customer || '.000' || acl.t_limit_ref
    JOIN lim_info li  ON li.limit_hashkey     = lh.limit_hashkey
    WHERE acl.t_limit_ref IN ('1200.01','1300.01')
),
pd_hub AS (
    SELECT h.loans_payment_due_hashkey, h.business_key
    FROM IDENTIFIER(:cleaned || '.raw_vault.hub_loans_payment_due') h
    LEFT JOIN (
        SELECT loans_payment_due_hashkey
        FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_loans_payment_due')
        WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
        GROUP BY loans_payment_due_hashkey
        HAVING max_by(cdc_status, source_event_date) = 'D'
    ) sts ON sts.loans_payment_due_hashkey = h.loans_payment_due_hashkey
    WHERE sts.loans_payment_due_hashkey IS NULL
      AND h.source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
      AND h.record_source      = 't24__t24_payment_due'
),
pd_over AS (
    SELECT loans_payment_due_hashkey, t_pay_type, t_pay_amt_outs
    FROM pd_over_cur
),
pd_contract AS (
    SELECT loans_payment_due_hashkey,
           max_by(t_orig_limit_ref, source_event_date) AS t_orig_limit_ref
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_loans_payment_due_contract')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_payment_due_hashkey
),
pd_info AS (
    SELECT loans_payment_due_hashkey,
           max_by(t_payment_dte_due, source_event_date) AS t_payment_dte_due
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_loans_payment_due_information')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_payment_due_hashkey
),
pd_sv AS (
    SELECT
        pc.t_orig_limit_ref                                                       AS t_orig_limit_ref,
        p2.pay_type_sv                                                            AS pay_type,
        CAST(split(coalesce(split(coalesce(po.t_pay_amt_outs, ''), '::')[p1.pos], ''),
                   '!!')[p2.pos] AS DECIMAL(20,4))                                AS pay_amt_outs,
        split(coalesce(pi.t_payment_dte_due, ''), '::')[p1.pos]                    AS payment_dte_due
    FROM pd_hub h
    JOIN      pd_over     po ON po.loans_payment_due_hashkey = h.loans_payment_due_hashkey
    LEFT JOIN pd_contract pc ON pc.loans_payment_due_hashkey = h.loans_payment_due_hashkey
    LEFT JOIN pd_info     pi ON pi.loans_payment_due_hashkey = h.loans_payment_due_hashkey
    LATERAL VIEW posexplode(split(coalesce(po.t_pay_type, ''),  '::')) p1 AS pos, pay_type_mv
    LATERAL VIEW posexplode(split(coalesce(p1.pay_type_mv, ''), '!!')) p2 AS pos, pay_type_sv
),
payment_due_sv_by_type AS (
    SELECT
        t_orig_limit_ref,
        pay_type                                                                   AS t_pay_type,
        CAST(SUM(COALESCE(pay_amt_outs, 0)) AS DECIMAL(20,4))                      AS pay_amt_outs,
        CAST(DATEDIFF(TO_DATE(:target_date, 'yyyyMMdd'),
                      TO_DATE(MAX(payment_dte_due), 'yyyyMMdd')) AS INT)           AS num_of_day
    FROM pd_sv
    GROUP BY t_orig_limit_ref, pay_type
),
payment_due_sv AS (
    SELECT
        t.t_orig_limit_ref                                                         AS t_orig_limit_ref,
        CAST(SUM(COALESCE(t.pay_amt_outs, 0)) AS DECIMAL(20,4))                                 AS tc_pd_amount_eq,
        CAST(SUM(CASE WHEN t.t_pay_type='PR' THEN COALESCE(t.pay_amt_outs, 0) ELSE 0 END) AS DECIMAL(20,4)) AS tc_pr_amt,
        CAST(SUM(CASE WHEN t.t_pay_type='IN' THEN COALESCE(t.pay_amt_outs, 0) ELSE 0 END) AS DECIMAL(20,4)) AS tc_in_amt,
        CAST(SUM(CASE WHEN t.t_pay_type='PE' THEN COALESCE(t.pay_amt_outs, 0) ELSE 0 END) AS DECIMAL(20,4)) AS tc_pe_amt,
        CAST(SUM(CASE WHEN t.t_pay_type='PS' THEN COALESCE(t.pay_amt_outs, 0) ELSE 0 END) AS DECIMAL(20,4)) AS tc_ps_amt,
        CAST(MAX(CASE WHEN t.t_pay_type='PR' THEN t.num_of_day ELSE 0 END) AS INT) AS tc_pr_num_of_day,
        CAST(MAX(CASE WHEN t.t_pay_type='IN' THEN t.num_of_day ELSE 0 END) AS INT) AS tc_in_num_of_day,
        CAST(MAX(CASE WHEN t.t_pay_type='PE' THEN t.num_of_day ELSE 0 END) AS INT) AS tc_pe_num_of_day,
        CAST(MAX(CASE WHEN t.t_pay_type='PS' THEN t.num_of_day ELSE 0 END) AS INT) AS tc_ps_num_of_day,
        CAST(1 AS INT)                                                             AS tc_is_pd_due_sv
    FROM payment_due_sv_by_type t
    GROUP BY t.t_orig_limit_ref
),
pd_ind AS (
    SELECT ll.loans_hashkey,
           MAX(sc.t_industry_lev1) AS pd_industry_lev1,
           MAX(sc.t_industry_lev3) AS pd_industry_lev3
    FROM ln_pd_cur ll
    JOIN ( SELECT loans_payment_due_hashkey,
           max_by(t_industry_lev1, source_event_date) AS t_industry_lev1,
           max_by(t_industry_lev3, source_event_date) AS t_industry_lev3
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_loans_payment_due_classification')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_payment_due_hashkey ) sc
      ON sc.loans_payment_due_hashkey = ll.loans_payment_due_hashkey
    GROUP BY ll.loans_hashkey
),

comb_hub AS (
    SELECT consumer_loan_hashkey
    FROM comb_active
),
-- sat_consumer_loan cu da bi tach thanh _information / _classification / _balance.
-- Moi CTE tu dedup ve 1 dong/consumer_loan_hashkey TRUOC khi join -> grain khong doi.
comb_sat_inf AS (
    SELECT consumer_loan_hashkey,
           max_by(term, source_event_date) AS term,
           max_by(purpose_id, source_event_date) AS purpose_id,
           max_by(purpose_name, source_event_date) AS purpose_name,
           max_by(loan_subproduct_name, source_event_date) AS loan_subproduct_name
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_consumer_loan_information')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY consumer_loan_hashkey
),
comb_sat_cls AS (
    SELECT consumer_loan_hashkey,
           max_by(loan_subproduct, source_event_date) AS loan_subproduct
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_consumer_loan_classification')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY consumer_loan_hashkey
),
comb_sat AS (
    SELECT i.consumer_loan_hashkey,
           i.term,
           i.purpose_id,
           i.purpose_name,
           c.loan_subproduct,
           i.loan_subproduct_name
    FROM      comb_sat_inf i
    LEFT JOIN comb_sat_cls c ON c.consumer_loan_hashkey = i.consumer_loan_hashkey
),
comb AS (
    SELECT h.consumer_loan_hashkey,
           s.term AS term_comb, s.purpose_id AS purpose_id_comb,
           s.purpose_name AS purpose_name_comb,
           s.loan_subproduct AS loan_subproduct_comb,
           s.loan_subproduct_name AS loan_subproduct_name_comb,
           1 AS is_comb
    FROM comb_hub h
    JOIN comb_sat s ON s.consumer_loan_hashkey = h.consumer_loan_hashkey
),

ou AS (
    SELECT OU_ID, OU_CODE, OU_NM, PRN_OU_CODE, PRN_OU_NM
    FROM cb_ou_dim
    WHERE EFF_TO_DT IS NULL
),
cust AS (
    SELECT hc.business_key AS cif,
           TRIM(CONCAT(COALESCE(si.name_1,''), ' ', COALESCE(si.name_2,''))) AS full_name
    FROM IDENTIFIER(:cleaned || '.business_vault.pit_customer') pit
    JOIN customer_active hc ON hc.customer_hashkey = pit.customer_hashkey
    LEFT JOIN ( SELECT customer_hashkey, source_event_date, name_1, name_2
                FROM IDENTIFIER(:cleaned || '.raw_vault.sat_customer_information')
                WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd') ) si
      ON si.customer_hashkey    = pit.customer_hashkey
     AND si.source_event_date   = pit.sat_customer_information_src_ev_dt
    WHERE pit.snapshot_date = TO_DATE(:target_date, 'yyyyMMdd')
),
ld_officer AS (
    SELECT l.loans_hashkey,
           ho.business_key AS account_officer_id,
           si.t_name       AS account_officer_name
    FROM ( SELECT loans_hashkey,
           max_by(dept_acct_officer_hashkey, source_event_date) AS dept_acct_officer_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.link_loans_dept_acct_officer_nvql')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY loans_hashkey ) l
    JOIN ofcr_active ho ON ho.dept_acct_officer_hashkey = l.dept_acct_officer_hashkey
    LEFT JOIN ofcr_info_cur si ON si.dept_acct_officer_hashkey = ho.dept_acct_officer_hashkey
),
exg AS (
    SELECT max_by(ref_code, source_event_date) AS ccy_code,
           max_by(t_mid_reval_rate, source_event_date) AS exg_rate_val
    FROM IDENTIFIER(:cleaned || '.raw_vault.ref_currency')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY ref_code
),

prvn_nhomno AS (
    SELECT lc.loans_hashkey, ac.asset_class AS nhom_no
    FROM ln_cust_cur lc
    JOIN cust_cls_cur ac ON ac.customer_hashkey = lc.customer_hashkey
),
prvn_dim AS (
    SELECT CST_LN_CL_DIM_ID, PRVN_RATE AS prvn_rate_dim
    FROM cst_ln_cl_dim
),
prvn_loan_limit AS (
    SELECT loans_hashkey, limit_hashkey
    FROM ln_limit_cur
),
rt_all AS (
    SELECT AR_ID, BAL_AMT_LCY
    FROM rt_base
),
prvn_lmt_loan AS (
    SELECT ll.limit_hashkey,
           CAST(SUM(COALESCE(a.BAL_AMT_LCY, 0)) AS DECIMAL(20,0)) AS ln_tot_amt_lmt
    FROM prvn_loan_limit ll
    JOIN rt_all a  ON a.AR_ID = ll.loans_hashkey
    LEFT JOIN del_limit dl ON dl.limit_hashkey = ll.limit_hashkey
    WHERE dl.limit_hashkey IS NULL
    GROUP BY ll.limit_hashkey
),
prvn_lmt_coll AS (
    SELECT lrl.limit_hashkey,
           CAST(SUM(cv.t_central_bank_value * COALESCE(ex.exg_rate_val,1)
                    * COALESCE(cr.t_percent_alloc,100) / 100)
                AS DECIMAL(20,0))                         AS tot_cnrl_bnk_clt_amt_lmt
    FROM coll_rl_cur lrl
    JOIN coll_cr_cur lcr
          ON lcr.collateral_right_hashkey = lrl.collateral_right_hashkey
    JOIN ( SELECT collateral_hashkey,
           max_by(t_central_bank_value, source_event_date) AS t_central_bank_value
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_collateral_valuation')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY collateral_hashkey ) cv
          ON cv.collateral_hashkey = lcr.collateral_hashkey
    LEFT JOIN coll_info_cur ci ON ci.collateral_hashkey = lcr.collateral_hashkey
    LEFT JOIN exg ex ON ex.ccy_code = ci.t_currency
    LEFT JOIN ( SELECT collateral_right_hashkey,
           max_by(t_percent_alloc, source_event_date) AS t_percent_alloc
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_collateral_right_information')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY collateral_right_hashkey ) cr
          ON cr.collateral_right_hashkey = lrl.collateral_right_hashkey
    LEFT JOIN del_collateral       dc  ON dc.collateral_hashkey        = lcr.collateral_hashkey
    LEFT JOIN del_collateral_right dcr ON dcr.collateral_right_hashkey = lrl.collateral_right_hashkey
    LEFT JOIN del_limit            dl  ON dl.limit_hashkey             = lrl.limit_hashkey
    WHERE dc.collateral_hashkey        IS NULL
      AND dcr.collateral_right_hashkey IS NULL
      AND dl.limit_hashkey             IS NULL
    GROUP BY lrl.limit_hashkey
),
gl97 AS (
    SELECT DISTINCT h.loans_hashkey
    FROM ( SELECT max_by(GL, source_event_date) AS GL,
           max_by(TIEUKHOAN, source_event_date) AS TIEUKHOAN
    FROM IDENTIFIER(:cleaned || '.business_vault.csat_crb_balance')
    WHERE source_event_date = TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY crb_hashkey
    HAVING SUBSTR(CAST(GL AS STRING),1,2) = '97' ) crb
    JOIN ld_hub h ON h.business_key =
         CASE WHEN SUBSTR(crb.TIEUKHOAN,1,2) = 'TF'             THEN SUBSTR(crb.TIEUKHOAN,1,12)
              WHEN SUBSTR(crb.TIEUKHOAN,1,4) IN ('PDLD','PDMD') THEN SUBSTR(crb.TIEUKHOAN,3)
              ELSE crb.TIEUKHOAN END
),
prvn AS (
    SELECT
        rt.AR_ID                                                    AS loans_hashkey,
        CAST(CASE WHEN g97.loans_hashkey IS NOT NULL THEN 0
                  ELSE dim.prvn_rate_dim END AS DECIMAL(10,4))      AS PRVN_RATE,
        CAST(CASE WHEN lm.ln_tot_amt_lmt IS NULL OR lm.ln_tot_amt_lmt = 0 THEN 0
                  ELSE (rt.BAL_AMT_FCY / lm.ln_tot_amt_lmt) * cl.tot_cnrl_bnk_clt_amt_lmt
             END AS DECIMAL(20,0))                                  AS CLT_AMT_LN,
        CAST(CASE WHEN g97.loans_hashkey IS NOT NULL THEN 0
                  WHEN lm.ln_tot_amt_lmt IS NULL OR lm.ln_tot_amt_lmt = 0 THEN 0
                  ELSE GREATEST(rt.BAL_AMT_LCY - (rt.BAL_AMT_FCY / lm.ln_tot_amt_lmt) * cl.tot_cnrl_bnk_clt_amt_lmt, 0)
                       * dim.prvn_rate_dim
             END AS DECIMAL(20,0))                                  AS PRVN_AMT
    FROM rt
    LEFT JOIN ld_hub h            ON h.loans_hashkey  = rt.AR_ID
    LEFT JOIN prvn_nhomno nn      ON nn.loans_hashkey = h.loans_hashkey
    LEFT JOIN prvn_dim dim         ON dim.CST_LN_CL_DIM_ID = nn.nhom_no
    LEFT JOIN prvn_loan_limit lkl ON lkl.loans_hashkey = h.loans_hashkey
    LEFT JOIN prvn_lmt_loan lm    ON lm.limit_hashkey  = lkl.limit_hashkey
    LEFT JOIN prvn_lmt_coll cl    ON cl.limit_hashkey  = lkl.limit_hashkey
    LEFT JOIN gl97 g97            ON g97.loans_hashkey = rt.AR_ID
),
coll AS (
    SELECT h.loans_hashkey, MAX(ci.t_collateral_type) AS collateral_type
    FROM prvn_loan_limit ll
    JOIN ld_hub h ON h.loans_hashkey = ll.loans_hashkey
    JOIN coll_rl_cur lrl
          ON lrl.limit_hashkey = ll.limit_hashkey
    JOIN coll_cr_cur lcr
          ON lcr.collateral_right_hashkey = lrl.collateral_right_hashkey
    LEFT JOIN coll_info_cur ci ON ci.collateral_hashkey = lcr.collateral_hashkey
    LEFT JOIN del_collateral       dc  ON dc.collateral_hashkey        = lcr.collateral_hashkey
    LEFT JOIN del_collateral_right dcr ON dcr.collateral_right_hashkey = lrl.collateral_right_hashkey
    LEFT JOIN del_limit            dl  ON dl.limit_hashkey             = lrl.limit_hashkey
    WHERE dc.collateral_hashkey        IS NULL
      AND dcr.collateral_right_hashkey IS NULL
      AND dl.limit_hashkey             IS NULL
    GROUP BY h.loans_hashkey
),
sched_item AS (
    SELECT s.loans_hashkey, s.t_sch_type,
           s.t_k_date                         AS shd_dt,
           CAST(s.t_amount AS DECIMAL(20,4))  AS shd_amt
    FROM ( SELECT loans_hashkey, t_sch_type, t_k_date, t_amount
           FROM sched_cur
           WHERE t_sch_type IN ('P','I')
             AND cycled_dates_seq = 1 ) s
    LEFT JOIN sts_sched_del del ON del.loans_hashkey = s.loans_hashkey
    WHERE del.loans_hashkey IS NULL
),
sched_day AS (
    SELECT loans_hashkey, t_sch_type, shd_dt, SUM(COALESCE(shd_amt, 0)) AS shd_amt
    FROM sched_item GROUP BY loans_hashkey, t_sch_type, shd_dt
),
sched_pick AS (
    SELECT loans_hashkey, t_sch_type, shd_dt, shd_amt,
           ROW_NUMBER() OVER (PARTITION BY loans_hashkey, t_sch_type
                ORDER BY CASE WHEN shd_dt >  TO_DATE(:target_date, 'yyyyMMdd') THEN shd_dt ELSE NULL END ASC  NULLS LAST) rn_next,
           ROW_NUMBER() OVER (PARTITION BY loans_hashkey, t_sch_type
                ORDER BY CASE WHEN shd_dt <= TO_DATE(:target_date, 'yyyyMMdd') THEN shd_dt ELSE NULL END DESC NULLS LAST) rn_last
    FROM sched_day
),
avi AS (
    SELECT sp.loans_hashkey,
        MAX(CASE WHEN t_sch_type='P' AND rn_next=1 AND shd_dt >  TO_DATE(:target_date, 'yyyyMMdd') THEN shd_dt  ELSE NULL END) AS NEXT_DATE,
        MAX(CASE WHEN t_sch_type='P' AND rn_next=1 AND shd_dt >  TO_DATE(:target_date, 'yyyyMMdd') THEN shd_amt ELSE NULL END) AS NEXT_AMT,
        MAX(CASE WHEN t_sch_type='P' AND rn_last=1 AND shd_dt <= TO_DATE(:target_date, 'yyyyMMdd') THEN shd_dt  ELSE NULL END) AS LAST_DATE,
        MAX(CASE WHEN t_sch_type='P' AND rn_last=1 AND shd_dt <= TO_DATE(:target_date, 'yyyyMMdd') THEN shd_amt ELSE NULL END) AS LAST_AMT,
        MAX(CASE WHEN t_sch_type='I' AND rn_next=1 AND shd_dt >  TO_DATE(:target_date, 'yyyyMMdd') THEN shd_dt  ELSE NULL END) AS NEXT_DATE_IN,
        MAX(CASE WHEN t_sch_type='I' AND rn_next=1 AND shd_dt >  TO_DATE(:target_date, 'yyyyMMdd') THEN shd_amt ELSE NULL END) AS NEXT_AMT_IN,
        MAX(CASE WHEN t_sch_type='I' AND rn_last=1 AND shd_dt <= TO_DATE(:target_date, 'yyyyMMdd') THEN shd_dt  ELSE NULL END) AS LAST_DATE_IN,
        MAX(CASE WHEN t_sch_type='I' AND rn_last=1 AND shd_dt <= TO_DATE(:target_date, 'yyyyMMdd') THEN shd_amt ELSE NULL END) AS LAST_AMT_IN
    FROM sched_pick sp
    GROUP BY sp.loans_hashkey
),
freq AS (
    SELECT s.loans_hashkey,
           MAX( DATE_FORMAT(s.t_k_date,'yyyyMMdd') || ' - ' || s.t_frequency ) AS FREQUENCY
    FROM ( SELECT loans_hashkey, t_k_date, t_frequency
           FROM sched_cur
           WHERE t_sch_type = 'R' AND cycled_dates_seq = 1 ) s
    GROUP BY s.loans_hashkey
),
penint AS (
    SELECT ll.loans_hashkey, MAX(po.t_penalty_rate) AS penalty_rate
    FROM ln_pd_cur ll
    JOIN pd_over_cur po ON po.loans_payment_due_hashkey = ll.loans_payment_due_hashkey
    WHERE po.t_penalty_rate IS NOT NULL
    GROUP BY ll.loans_hashkey
),
src_ik AS (
    SELECT INTEREST_KEY_ID, DSC_VIET
    FROM src_interest_key_desc
),

ref_category AS (
    SELECT ref_code,
           max_by(ref_description, source_event_date) AS ref_description
    FROM IDENTIFIER(:cleaned || '.raw_vault.ref_t24_category')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY ref_code
),
ref_subproduct AS (
    SELECT ref_code,
           max_by(ref_description, source_event_date) AS ref_description
    FROM IDENTIFIER(:cleaned || '.raw_vault.ref_t24_loan_subproduct')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY ref_code
),
ref_method AS (
    SELECT ref_code,
           max_by(ref_description, source_event_date) AS ref_description
    FROM IDENTIFIER(:cleaned || '.raw_vault.ref_t24_loan_method')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY ref_code
),
ref_purpose AS (
    SELECT ref_code,
           max_by(ref_description, source_event_date) AS ref_description
    FROM IDENTIFIER(:cleaned || '.raw_vault.ref_t24_loan_purpose')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY ref_code
),
ref_promotion AS (
    SELECT ref_code,
           max_by(ref_description, source_event_date) AS ref_description
    FROM IDENTIFIER(:cleaned || '.raw_vault.ref_t24_ld_promotion')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY ref_code
),
ref_partner AS (
    SELECT ref_code,
           max_by(ref_description, source_event_date) AS ref_description
    FROM IDENTIFIER(:cleaned || '.raw_vault.ref_t24_ld_partner')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY ref_code
),
ref_custgroup AS (
    SELECT ref_code,
           max_by(ref_description, source_event_date) AS ref_description
    FROM IDENTIFIER(:cleaned || '.raw_vault.ref_t24_ocbh_cus_group')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY ref_code
),
ref_sector AS (
    SELECT ref_code,
           max_by(ref_description, source_event_date) AS ref_description
    FROM IDENTIFIER(:cleaned || '.raw_vault.ref_t24_sector')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY ref_code
),
ref_industry AS (
    SELECT ref_code,
           max_by(ref_description, source_event_date) AS ref_description
    FROM IDENTIFIER(:cleaned || '.raw_vault.ref_t24_ld_economic_sector')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY ref_code
),

-- sat_consumer_loan_wo cu da bi tach thanh _wo_information / _wo_classification /
-- _wo_balance, va 2 cot customer_id + branch_code chuyen sang link.
-- Moi CTE dedup ve 1 dong/consumer_loan_hashkey TRUOC khi join. wo_sat giu nguyen
-- dung 30 cot nhu truoc nen khoi SELECT/JOIN phia duoi khong phai doi.
wo_inf AS (
    SELECT consumer_loan_hashkey,
           currency, mature_date, open_date, next_repayment_date, frequency,
           interest_rate, interest_type, term, purpose_id, purpose_name,
           extend_sch, extendsch_date, account_officer_id, link_reference,
           pr_day, in_day, interest_spread, loan_subproduct_name
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_consumer_loan_wo_information')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY consumer_loan_hashkey
                               ORDER BY source_event_date DESC) = 1
),
wo_cls AS (
    SELECT consumer_loan_hashkey,
           custgroup, loan_classification, industry_level_3, loan_subproduct
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_consumer_loan_wo_classification')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY consumer_loan_hashkey
                               ORDER BY source_event_date DESC) = 1
),
wo_bal AS (
    SELECT consumer_loan_hashkey,
           disbursment_amount, oustanding_amount, provision_oustanding,
           gl, pd_amount_eq, acrrual_balance
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_consumer_loan_wo_balance')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY consumer_loan_hashkey
                               ORDER BY source_event_date DESC) = 1
),
-- customer_id: link -> hub_customer.business_key. Rut current theo driving key
-- (consumer_loan_hashkey) TRUOC khi join de tranh fan-out khi hop dong doi CIF.
wo_cust_cur AS (
    SELECT l.consumer_loan_hashkey,
           hc.business_key AS customer_id
    FROM ( SELECT consumer_loan_hashkey,
                  max_by(customer_hashkey, source_event_date) AS customer_hashkey
           FROM IDENTIFIER(:cleaned || '.raw_vault.link_consumer_loan_customer')
           WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
           GROUP BY consumer_loan_hashkey ) l
    LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.hub_customer') hc
           ON hc.customer_hashkey = l.customer_hashkey
),
-- branch_code: link -> hub_branch.business_key, cung co che rut current.
wo_br_cur AS (
    SELECT l.consumer_loan_hashkey,
           hb.business_key AS branch_code
    FROM ( SELECT consumer_loan_hashkey,
                  max_by(branch_hashkey, source_event_date) AS branch_hashkey
           FROM IDENTIFIER(:cleaned || '.raw_vault.link_consumer_loan_branch')
           WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
           GROUP BY consumer_loan_hashkey ) l
    LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.hub_branch') hb
           ON hb.branch_hashkey = l.branch_hashkey
),
wo_sat AS (
    SELECT i.consumer_loan_hashkey,
           cu.customer_id, br.branch_code, i.currency, i.mature_date,
           i.open_date, bl.disbursment_amount, bl.oustanding_amount, cl.custgroup,
           cl.loan_classification, i.next_repayment_date, i.frequency, i.interest_rate,
           i.interest_type, cl.industry_level_3, i.term, i.purpose_id,
           i.purpose_name, i.extend_sch, i.extendsch_date, i.account_officer_id,
           bl.provision_oustanding, i.link_reference, bl.gl, bl.pd_amount_eq,
           i.pr_day, i.in_day, i.interest_spread, cl.loan_subproduct,
           i.loan_subproduct_name, bl.acrrual_balance
    FROM      wo_inf      i
    LEFT JOIN wo_cls      cl ON cl.consumer_loan_hashkey = i.consumer_loan_hashkey
    LEFT JOIN wo_bal      bl ON bl.consumer_loan_hashkey = i.consumer_loan_hashkey
    LEFT JOIN wo_cust_cur cu ON cu.consumer_loan_hashkey = i.consumer_loan_hashkey
    LEFT JOIN wo_br_cur   br ON br.consumer_loan_hashkey = i.consumer_loan_hashkey
),
wo_del AS (
    SELECT consumer_loan_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_consumer_loan_wo')
    WHERE source_event_date <= TO_DATE(:target_date, 'yyyyMMdd')
    GROUP BY consumer_loan_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
wo_sctr AS (
    SELECT hc.business_key AS cif, sc.sector AS ip_sctr, sc.cust_group AS cust_grp
    FROM customer_active hc
    LEFT JOIN cust_cls_cur sc ON sc.customer_hashkey = hc.customer_hashkey
),
base AS (
    SELECT
        rt.CDR_DT_ID, rt.AR_ID, rt.AR_NO, rt.OU_ID, rt.SCTR_ID, rt.OFCR_ID, rt.CST_GRP_ID,
        rt.GL, rt.CCY_ID, rt.LN_CL_BY_GL_ID, rt.OPN_DT, rt.MAT_DT,
        rt.BAL_AMT_FCY, rt.BAL_AMT_LCY, rt.BAL_INT_AMT_LCY, rt.OFFBAL_INT_AMT_LCY,
        rt.MX_PD_PR_DYS, rt.MX_PD_INT_DYS, rt.MX_PD_PE_DYS, rt.MX_PD_PS_DYS,
        rt.PD_PR_AMT, rt.PD_INT_AMT, rt.PD_PE_AMT, rt.PD_PS_AMT,
        rt.INT_RATE, rt.T24_LOAN_CLASS_CIF, rt.T24_LN_CLASS,
        ld.loans_hashkey, ld.t_interest_spread, ld.t_int_rate_type, ld.t_interest_key,
        ld.t_int_key_name, ld.t_tot_interest_amt, ld.t_category, ld.t_loan_subproduct,
        ld.t_loan_method, ld.t_industry_lev1, ld.t_industry_lev2, ld.t_industry_lev3,
        ld.t_liquidation_mode, ld.t_extend_sch, ld.t_extendsch_date, ld.t_ocb_promotion,
        ld.t_ocb_pro_partner, ld.t_ld_cust_group, ld.t_limit_reference, ld.t_link_reference,
        ld.t_legacy_ref,
        ld.t_drawdown_net_amt, ld.t_prin_liq_acct, ld.t_int_liq_acct, ld.t_status,
        ld.t_ln_class_manual, ld.t_term, ld.t_inputter, ld.t_authoriser, ld.t_cust_remarks,
        ld.t_customer_id, ld.ac_middleman_id, ld.ac_middleman_name, ld.t_loan_purpose,
        ld.t_fixed_variable, ld.t_credit_line,
        ou.OU_CODE, ou.OU_NM, ou.PRN_OU_CODE, ou.PRN_OU_NM,
        cst.full_name,
        ofc.account_officer_id, ofc.account_officer_name,
        cmb.is_comb, cmb.term_comb, cmb.purpose_id_comb, cmb.purpose_name_comb,
        cmb.loan_subproduct_comb, cmb.loan_subproduct_name_comb,
        alt.tc_is_acct_limit, alt.tc_limit_ref, alt.tc_limit_reference_3,
        alt.tc_internal_amount, alt.tc_online_limit_date, alt.tc_expiry_date, alt.tc_category,
        psv.tc_pd_amount_eq, psv.tc_pr_amt, psv.tc_in_amt, psv.tc_pe_amt, psv.tc_ps_amt,
        psv.tc_pr_num_of_day, psv.tc_in_num_of_day, psv.tc_pe_num_of_day, psv.tc_ps_num_of_day,
        psv.tc_is_pd_due_sv,
        pdi.pd_industry_lev1, pdi.pd_industry_lev3,
        pr.PRVN_RATE, pr.PRVN_AMT, pr.CLT_AMT_LN,
        co.collateral_type       AS COLLATERAL_TYPE,
        av.NEXT_DATE, av.NEXT_AMT, av.LAST_DATE, av.LAST_AMT,
        av.NEXT_DATE_IN, av.NEXT_AMT_IN, av.LAST_DATE_IN, av.LAST_AMT_IN,
        fr.FREQUENCY,
        pn.penalty_rate               AS penalty_rate,
        CAST(NULL AS DECIMAL(20,10))  AS penalty_spread,
        sik.DSC_VIET       AS interest_key_desc,
        rcat.ref_description      AS category_desc,
        rcat_tt03.ref_description AS tc_category_desc,
        rsub.ref_description      AS loan_subproduct_desc,
        rlm.ref_description       AS loan_method_desc,
        rcg.ref_description       AS custgroup_desc,
        rlp.ref_description       AS main_purpose_name,
        rlp208.ref_description    AS purpose_name_208,
        rlp512.ref_description    AS purpose_name_512,
        rpr.ref_description       AS promotion_name,
        rpn.ref_description       AS product_partner_name,
        rse.ref_code              AS sector_code,
        SPLIT(rse.ref_description,'::')[1] AS sector_desc,
        ri1.ref_description       AS industry_lev1_desc,
        ri2.ref_description       AS industry_lev2_desc,
        ri3.ref_description       AS industry_lev3_desc,
        CASE WHEN rt.BAL_AMT_FCY <> 0 THEN rt.BAL_AMT_LCY / rt.BAL_AMT_FCY
             ELSE ex.EXG_RATE_VAL END                                   AS ld_exg_rate_val,
        COALESCE(alt.tc_is_acct_limit, 0)                              AS tc_is_acct_limit_f,
        CASE WHEN COALESCE(psv.tc_is_pd_due_sv, 0) <> 0
                  AND RIGHT(ld.t_customer_id || '.' || LPAD(ld.t_limit_reference, 10, '0'), 7)
                      IN ('1200.01', '1300.01')
             THEN 1 ELSE 0 END                                         AS isupdatelimitref3
    FROM rt
    LEFT JOIN loans          ld  ON ld.loans_hashkey = rt.AR_ID
    LEFT JOIN ou                 ON ou.OU_ID = rt.OU_ID
    LEFT JOIN cust           cst ON cst.cif = ld.t_customer_id
    LEFT JOIN ld_officer     ofc ON ofc.loans_hashkey = ld.loans_hashkey
    LEFT JOIN comb           cmb ON cmb.consumer_loan_hashkey = rt.AR_ID
    LEFT JOIN acct_limit_tt03 alt ON alt.tc_account_no = rt.AR_NO
                                 AND CAST(ld.t_category AS INT) BETWEEN 1001 AND 1099
    LEFT JOIN payment_due_sv psv ON psv.t_orig_limit_ref = rt.AR_NO
    LEFT JOIN pd_ind         pdi ON pdi.loans_hashkey = rt.AR_ID
    LEFT JOIN prvn           pr  ON pr.loans_hashkey = rt.AR_ID
    LEFT JOIN coll           co  ON co.loans_hashkey = rt.AR_ID
    LEFT JOIN avi            av  ON av.loans_hashkey = rt.AR_ID
    LEFT JOIN freq           fr  ON fr.loans_hashkey = rt.AR_ID
    LEFT JOIN exg            ex  ON ex.ccy_code = rt.CCY_ID
    LEFT JOIN penint         pn  ON pn.loans_hashkey = rt.AR_ID
    LEFT JOIN src_ik         sik ON CAST(sik.INTEREST_KEY_ID AS STRING) = CAST(ld.t_interest_key AS STRING)
    LEFT JOIN ref_category   rcat ON CAST(rcat.ref_code AS STRING) = CAST(ld.t_category AS STRING)
    LEFT JOIN ref_category   rcat_tt03 ON CAST(rcat_tt03.ref_code AS STRING) = CAST(alt.tc_category AS STRING)
    LEFT JOIN ref_subproduct rsub ON CAST(rsub.ref_code AS STRING) = CAST(ld.t_loan_subproduct AS STRING)
    LEFT JOIN ref_method     rlm  ON CAST(rlm.ref_code AS STRING)  = CAST(ld.t_loan_method AS STRING)
    LEFT JOIN ref_custgroup  rcg  ON CAST(rcg.ref_code AS STRING)  = CAST(ld.t_ld_cust_group AS STRING)
    LEFT JOIN ref_purpose    rlp  ON CAST(rlp.ref_code AS STRING)  = CAST(ld.t_loan_purpose AS STRING)
    LEFT JOIN ref_purpose    rlp208 ON CAST(rlp208.ref_code AS STRING) = '208'
    LEFT JOIN ref_purpose    rlp512 ON CAST(rlp512.ref_code AS STRING) = '512'
    LEFT JOIN ref_promotion  rpr  ON CAST(rpr.ref_code AS STRING)  = CAST(ld.t_ocb_promotion AS STRING)
    LEFT JOIN ref_partner    rpn  ON CAST(rpn.ref_code AS STRING)  = CAST(ld.t_ocb_pro_partner AS STRING)
    LEFT JOIN ref_sector     rse  ON CAST(rse.ref_code AS STRING) = CAST(ld.sctr_code AS STRING)
    LEFT JOIN ref_industry   ri1  ON CAST(ri1.ref_code AS STRING)  = CAST(COALESCE(ld.t_industry_lev1, pdi.pd_industry_lev1) AS STRING)
    LEFT JOIN ref_industry   ri2  ON CAST(ri2.ref_code AS STRING)  = CAST(ld.t_industry_lev2 AS STRING)
    LEFT JOIN ref_industry   ri3  ON CAST(ri3.ref_code AS STRING)  = CAST(COALESCE(ld.t_industry_lev3, pdi.pd_industry_lev3) AS STRING)
)

SELECT
    CAST(:target_date AS INT)                                            AS CDR_DT_ID,
    b.AR_NO                                                         AS LD_NO,
    b.t_legacy_ref                                                AS LD_NO_OLD,
    b.SCTR_ID                                                      AS BDW_SCTR_ID,
    b.OFCR_ID                                                      AS OFCR_ID,
    b.CST_GRP_ID                                                   AS BDW_CST_GRP_ID,
    b.AR_ID                                                        AS AR_ID,
    b.OU_ID                                                        AS OU_ID,
    b.t_link_reference                                            AS LINK_REFERENCE,
    b.t_customer_id                                               AS CIF,
    b.product_partner_name                                        AS OCB_PRODUCT_PARTNER_NAME,
    b.t_ocb_pro_partner                                          AS OCB_PRODUCT_PARTNER_ID,
    b.full_name                                                   AS FULL_NAME,
    b.OU_CODE                                                     AS BRANCH_CODE,
    b.OU_NM                                                       AS BRANCH_NAME,
    b.PRN_OU_CODE                                                AS BRANCH_PARENT_CODE,
    b.PRN_OU_NM                                                  AS BRANCH_PARENT_NAME,
    b.GL                                                          AS GL,
    b.t_inputter                                                 AS INPUTTER,
    b.t_authoriser                                               AS AUTHORISER,
    b.t_fixed_variable                                           AS FIXED_VARIABLE,
    CASE WHEN b.tc_is_acct_limit_f <> 0 THEN b.tc_limit_ref
         ELSE b.t_credit_line END                                AS LIMIT_REFERENCE_1,
    CASE WHEN b.tc_is_acct_limit_f <> 0 THEN b.tc_limit_reference_3
         ELSE ( b.t_customer_id || '.' || LPAD(b.t_limit_reference,10,'0') ) END AS LIMIT_REFERENCE_3,
    CAST(NULL AS STRING)                                         AS LIMIT_DESCRIPTION,
    b.CCY_ID                                                     AS CURRENCY,
    b.LN_CL_BY_GL_ID                                             AS LOAN_CLASSIFICATION,
    CASE WHEN b.tc_is_acct_limit_f <> 0 THEN TO_DATE(b.tc_online_limit_date,'yyyyMMdd')
         ELSE b.OPN_DT END                                       AS VALUE_DATE,
    CASE WHEN b.tc_is_acct_limit_f <> 0 THEN TO_DATE(b.tc_expiry_date,'yyyyMMdd')
         ELSE b.MAT_DT END                                       AS MATURE_DATE,
    CASE WHEN b.tc_is_acct_limit_f <> 0 THEN b.tc_internal_amount
         ELSE b.t_drawdown_net_amt END                          AS DRAW_DOWN_AMT,
    b.BAL_AMT_FCY                                                AS TOTAL_AMOUNT,
    b.BAL_AMT_LCY                                                AS TOTAL_AMOUNT_EQ,
    b.BAL_AMT_LCY - (CASE WHEN b.isupdatelimitref3 <> 0 THEN b.tc_pd_amount_eq
                          ELSE b.PD_PR_AMT * b.ld_exg_rate_val END)  AS LD_AMOUNT_EQ,
    CASE WHEN b.isupdatelimitref3 <> 0 THEN b.tc_pd_amount_eq
         ELSE b.PD_PR_AMT * b.ld_exg_rate_val END               AS PD_AMOUNT_EQ,
    b.BAL_INT_AMT_LCY                                            AS ACCURAL_AMT_394_EQ,
    b.OFFBAL_INT_AMT_LCY                                         AS ACCURAL_AMT_94_EQ,
    CASE WHEN b.isupdatelimitref3 <> 0 THEN b.tc_pr_num_of_day ELSE b.MX_PD_PR_DYS END AS PR_DAY,
    CASE WHEN b.isupdatelimitref3 <> 0 THEN b.tc_in_num_of_day ELSE b.MX_PD_INT_DYS END AS IN_DAY,
    CASE WHEN b.isupdatelimitref3 <> 0 THEN b.tc_pe_num_of_day ELSE b.MX_PD_PE_DYS END AS PE_DAY,
    CASE WHEN b.isupdatelimitref3 <> 0 THEN b.tc_ps_num_of_day ELSE b.MX_PD_PS_DYS END AS PS_DAY,
    CASE WHEN b.isupdatelimitref3 <> 0 THEN b.tc_pr_amt ELSE b.PD_PR_AMT END AS PR,
    CASE WHEN b.isupdatelimitref3 <> 0 THEN b.tc_in_amt ELSE b.PD_INT_AMT END AS IN,
    CASE WHEN b.isupdatelimitref3 <> 0 THEN b.tc_pe_amt ELSE b.PD_PE_AMT END AS PE,
    CASE WHEN b.isupdatelimitref3 <> 0 THEN b.tc_ps_amt ELSE b.PD_PS_AMT END AS PS,
    CASE WHEN b.is_comb = 1 THEN b.term_comb ELSE b.t_term END   AS TERM,
    b.INT_RATE                                                   AS INTERATE_RATE,
    b.t_interest_spread                                          AS INTEREST_SPREAD,
    CAST(CAST(b.t_int_rate_type AS DECIMAL(38,0)) AS STRING)      AS INT_RATE_TYPE,
    b.t_interest_key                                             AS INTEREST_KEY,
    b.FREQUENCY                                                  AS FREQUENCY,
    b.penalty_rate                                               AS PENALTY_RATE,
    b.penalty_spread                                             AS PENALTY_SPREAD,
    CASE WHEN b.is_comb = 1 THEN b.purpose_id_comb
         WHEN b.tc_is_acct_limit_f <> 0 THEN
              (CASE WHEN LEFT(b.sector_code,1) = '1' THEN '208' ELSE '512' END)
         ELSE CAST(b.t_loan_purpose AS STRING) END             AS MAIN_PURPOSE_NO,
    CASE WHEN b.is_comb = 1 THEN b.purpose_name_comb
         WHEN b.tc_is_acct_limit_f <> 0 THEN
              (CASE WHEN LEFT(b.sector_code,1) = '1' THEN b.purpose_name_208 ELSE b.purpose_name_512 END)
         ELSE b.main_purpose_name END                          AS MAIN_PURPOSE_NAME,
    CAST(NULL AS STRING)                                         AS INDUSTRY,
    CAST(NULL AS STRING)                                         AS INDUSTRY_DESCRIPTION,
    COALESCE(b.t_industry_lev1, b.pd_industry_lev1)              AS INDUSTRY_LEV1,
    b.t_industry_lev2                                            AS INDUSTRY_LEV2,
    COALESCE(b.t_industry_lev3, b.pd_industry_lev3)              AS INDUSTRY_LEV3,
    b.industry_lev1_desc                                         AS INDUSTRY_LEV1_DESC,
    b.industry_lev2_desc                                         AS INDUSTRY_LEV2_DESC,
    b.industry_lev3_desc                                         AS INDUSTRY_LEV3_DESC,
    b.sector_code                                                AS SECTOR,
    b.sector_desc                                                AS SECTOR_DESCRIPTION,
    b.ld_exg_rate_val                                            AS RATE,
    b.PRVN_RATE                                                  AS RATE_PROVISION,
    b.PRVN_AMT                                                   AS PROVISION_AMT,
    b.CLT_AMT_LN                                                 AS COLLATERAL_AMOUNT,
    b.COLLATERAL_TYPE                                            AS COLLATERAL_TYPE,
    CAST(NULL AS STRING)                                         AS COLLATERAL_NOMINAL,
    CASE WHEN b.tc_is_acct_limit_f <> 0 THEN b.tc_category ELSE b.t_category END AS CATEGORY,
    CASE WHEN b.is_comb = 1             THEN b.loan_subproduct_name_comb
         WHEN b.tc_is_acct_limit_f <> 0 THEN b.tc_category_desc
         ELSE b.category_desc END                               AS CATEGORY_DESCRIPTION,
    CASE WHEN b.is_comb = 1 THEN b.loan_subproduct_comb
         ELSE CAST(b.t_loan_subproduct AS STRING) END           AS LOAN_SUBPRODUCT,
    CASE WHEN b.is_comb = 1 THEN b.loan_subproduct_name_comb
         ELSE b.loan_subproduct_desc END                        AS LOAN_SUBPRODUCT_DESC,
    CAST(b.t_loan_method AS STRING)                             AS LOAN_METHOD,
    b.loan_method_desc                                          AS LOAN_METHOD_DESC,
    b.t_cust_remarks                                            AS CUST_REMARKS,
    CAST(NULL AS STRING)                                         AS CLASSIFICATION,
    b.t_ld_cust_group                                          AS CUSTGROUP,
    b.custgroup_desc                                            AS CUSTGROUP_DESCRIPTION,
    CAST(NULL AS STRING)                                         AS OVERDUE_STATUS,
    b.account_officer_id                                        AS ACCOUNT_OFFICER_ID,
    b.account_officer_name                                      AS ACCOUNT_OFFICER_NAME,
    b.t_liquidation_mode                                       AS LIQUIDATION_MODE,
    b.t_ln_class_manual                                        AS LN_CLASS_MANUAL,
    b.t_extend_sch                                             AS EXTEND_SCH,
    b.t_extendsch_date                                         AS EXTENDSCH_DATE,
    b.t_ocb_promotion                                          AS PROMOTION_ID,
    b.promotion_name                                            AS PROMOTION_NAME,
    CURRENT_TIMESTAMP()                                         AS CRT_TM,
    CURRENT_TIMESTAMP()                                         AS PPN_TM,
    CASE WHEN CAST(b.t_int_rate_type AS INT) = 1 THEN N'FIX' ELSE N'VAR' END  AS INT_RATE_TYPE_DESC,
    b.interest_key_desc                                        AS INTEREST_KEY_DESC,
    b.ac_middleman_id                                          AS AC_MIDDLEMAN_ID,
    b.ac_middleman_name                                        AS AC_MIDDLEMAN_NAME,
    CAST(NULL AS DECIMAL(20,4))                                 AS PROVISION_OUSTANDING,
    CASE WHEN b.tc_is_acct_limit_f <> 0 THEN NULLIF(b.tc_expiry_date,'')
         ELSE DATE_FORMAT(b.NEXT_DATE,'yyyyMMdd') END          AS NEXT_REPAYMENT_DATE,
    b.t_tot_interest_amt                                       AS TOTAL_INTEREST_AMT,
    b.NEXT_AMT                                                 AS NEXT_REPAYMENT_AMT_PR,
    b.t_prin_liq_acct                                         AS REPAYMENT_ACCOUNT,
    b.t_int_liq_acct                                          AS INT_LIQ_ACCT,
    DATE_FORMAT(b.LAST_DATE,'yyyyMMdd')                        AS PREV_REPAYMENT_DATE,
    NULLIF(b.LAST_AMT,0)                                       AS PREV_REPAYMENT_AMT_PR,
    b.BAL_AMT_FCY - (CASE WHEN b.isupdatelimitref3 <> 0 THEN b.tc_pr_amt ELSE b.PD_PR_AMT END) AS LD_AMOUNT,
    DATE_FORMAT(b.NEXT_DATE_IN,'yyyyMMdd')                     AS NEXT_DATE_IN,
    NULLIF(b.NEXT_AMT_IN,0)                                    AS NEXT_AMT_IN,
    DATE_FORMAT(b.LAST_DATE_IN,'yyyyMMdd')                     AS LAST_DATE_IN,
    NULLIF(b.LAST_AMT_IN,0)                                    AS LAST_AMT_IN,
    COALESCE(b.is_comb,0)                                      AS IS_COMB,
    b.T24_LOAN_CLASS_CIF                                       AS T24_LOAN_CLASS_CIF,
    b.T24_LN_CLASS                                             AS T24_LN_CLASS
FROM base b
UNION ALL
SELECT
    CAST(:target_date AS INT)                                                     AS CDR_DT_ID,
    h.business_key                                                           AS LD_NO,
    CAST(NULL AS STRING)                                                     AS LD_NO_OLD,
    wsc.ip_sctr                                                              AS BDW_SCTR_ID,
    100000038                                                                AS OFCR_ID,
    wsc.cust_grp                                                             AS BDW_CST_GRP_ID,
    s.consumer_loan_hashkey                                                  AS AR_ID,
    ou2.OU_ID                                                                AS OU_ID,
    s.link_reference                                                         AS LINK_REFERENCE,
    s.customer_id                                                            AS CIF,
    CAST(NULL AS STRING)                                                     AS OCB_PRODUCT_PARTNER_NAME,
    CAST(NULL AS STRING)                                                     AS OCB_PRODUCT_PARTNER_ID,
    cst2.full_name                                                           AS FULL_NAME,
    s.branch_code                                                            AS BRANCH_CODE,
    ou2.OU_NM                                                                AS BRANCH_NAME,
    ou2.PRN_OU_CODE                                                          AS BRANCH_PARENT_CODE,
    ou2.PRN_OU_NM                                                            AS BRANCH_PARENT_NAME,
    s.gl                                                                     AS GL,
    CAST(NULL AS STRING)                                                     AS INPUTTER,
    CAST(NULL AS STRING)                                                     AS AUTHORISER,
    CAST(NULL AS STRING)                                                     AS FIXED_VARIABLE,
    CAST(NULL AS STRING)                                                     AS LIMIT_REFERENCE_1,
    CAST(NULL AS STRING)                                                     AS LIMIT_REFERENCE_3,
    CAST(NULL AS STRING)                                                     AS LIMIT_DESCRIPTION,
    s.currency                                                               AS CURRENCY,
    s.loan_classification                                                    AS LOAN_CLASSIFICATION,
    CASE WHEN s.open_date IS NULL THEN NULL ELSE TO_DATE(CAST(s.open_date AS STRING),'yyyyMMdd') END AS VALUE_DATE,
    CASE WHEN s.mature_date IS NULL THEN NULL ELSE TO_DATE(CAST(s.mature_date AS STRING),'yyyyMMdd') END AS MATURE_DATE,
    CAST(NULL AS DECIMAL(20,4))                                              AS DRAW_DOWN_AMT,
    s.oustanding_amount                                                      AS TOTAL_AMOUNT,
    s.oustanding_amount                                                      AS TOTAL_AMOUNT_EQ,
    s.disbursment_amount                                                     AS LD_AMOUNT_EQ,
    s.pd_amount_eq                                                           AS PD_AMOUNT_EQ,
    0                                                                        AS ACCURAL_AMT_394_EQ,
    s.acrrual_balance                                                        AS ACCURAL_AMT_94_EQ,
    s.pr_day                                                                 AS PR_DAY,
    s.in_day                                                                 AS IN_DAY,
    CAST(NULL AS INT)                                                        AS PE_DAY,
    CAST(NULL AS INT)                                                        AS PS_DAY,
    s.pd_amount_eq                                                           AS PR,
    s.acrrual_balance                                                        AS IN,
    CAST(NULL AS DECIMAL(20,4))                                              AS PE,
    CAST(NULL AS DECIMAL(20,4))                                              AS PS,
    s.term                                                                   AS TERM,
    s.interest_rate                                                          AS INTERATE_RATE,
    s.interest_spread                                                        AS INTEREST_SPREAD,
    CAST(s.interest_type AS STRING)                                          AS INT_RATE_TYPE,
    CAST(NULL AS STRING)                                                     AS INTEREST_KEY,
    s.frequency                                                              AS FREQUENCY,
    CAST(NULL AS DECIMAL(20,10))                                             AS PENALTY_RATE,
    CAST(NULL AS DECIMAL(20,10))                                             AS PENALTY_SPREAD,
    CAST(s.purpose_id AS STRING)                                             AS MAIN_PURPOSE_NO,
    s.purpose_name                                                           AS MAIN_PURPOSE_NAME,
    CAST(NULL AS STRING)                                                     AS INDUSTRY,
    CAST(NULL AS STRING)                                                     AS INDUSTRY_DESCRIPTION,
    CAST(NULL AS STRING)                                                     AS INDUSTRY_LEV1,
    CAST(NULL AS STRING)                                                     AS INDUSTRY_LEV2,
    s.industry_level_3                                                       AS INDUSTRY_LEV3,
    CAST(NULL AS STRING)                                                     AS INDUSTRY_LEV1_DESC,
    CAST(NULL AS STRING)                                                     AS INDUSTRY_LEV2_DESC,
    rin.ref_description                                                      AS INDUSTRY_LEV3_DESC,
    rse2.ref_code                                                            AS SECTOR,
    SPLIT(rse2.ref_description,'::')[1]                                      AS SECTOR_DESCRIPTION,
    CAST(NULL AS DECIMAL(20,10))                                             AS RATE,
    CAST(NULL AS DECIMAL(20,10))                                             AS RATE_PROVISION,
    CAST(NULL AS DECIMAL(20,4))                                              AS PROVISION_AMT,
    CAST(NULL AS DECIMAL(20,4))                                              AS COLLATERAL_AMOUNT,
    CAST(NULL AS STRING)                                                     AS COLLATERAL_TYPE,
    CAST(NULL AS STRING)                                                     AS COLLATERAL_NOMINAL,
    CAST(NULL AS STRING)                                                     AS CATEGORY,
    CAST(NULL AS STRING)                                                     AS CATEGORY_DESCRIPTION,
    s.loan_subproduct                                                        AS LOAN_SUBPRODUCT,
    s.loan_subproduct_name                                                   AS LOAN_SUBPRODUCT_DESC,
    CAST(NULL AS STRING)                                                     AS LOAN_METHOD,
    CAST(NULL AS STRING)                                                     AS LOAN_METHOD_DESC,
    CAST(NULL AS STRING)                                                     AS CUST_REMARKS,
    CAST(NULL AS STRING)                                                     AS CLASSIFICATION,
    wsc.cust_grp                                                             AS CUSTGROUP,
    rcg2.ref_description                                                     AS CUSTGROUP_DESCRIPTION,
    CAST(NULL AS STRING)                                                     AS OVERDUE_STATUS,
    '1'                                                                      AS ACCOUNT_OFFICER_ID,
    'Không xác định'                                                         AS ACCOUNT_OFFICER_NAME, 
    CAST(NULL AS STRING)                                                     AS LIQUIDATION_MODE,
    CAST(NULL AS STRING)                                                     AS LN_CLASS_MANUAL,
    s.extend_sch                                                             AS EXTEND_SCH,
    s.extendsch_date                                                         AS EXTENDSCH_DATE,
    CAST(NULL AS STRING)                                                     AS PROMOTION_ID,
    CAST(NULL AS STRING)                                                     AS PROMOTION_NAME,
    CURRENT_TIMESTAMP()                                                      AS CRT_TM,
    CURRENT_TIMESTAMP()                                                      AS PPN_TM,
    CAST(CASE WHEN CAST(s.interest_type AS INT) = 1 THEN N'FIX' ELSE N'VAR' END AS STRING) AS INT_RATE_TYPE_DESC,
    CAST(NULL AS STRING)                                                     AS INTEREST_KEY_DESC,
    CAST(NULL AS STRING)                                                     AS AC_MIDDLEMAN_ID,
    CAST(NULL AS STRING)                                                     AS AC_MIDDLEMAN_NAME,
    s.provision_oustanding                                                   AS PROVISION_OUSTANDING,
    s.next_repayment_date                                                    AS NEXT_REPAYMENT_DATE,
    CAST(NULL AS DECIMAL(20,4))                                              AS TOTAL_INTEREST_AMT,
    CAST(NULL AS DECIMAL(20,4))                                              AS NEXT_REPAYMENT_AMT_PR,
    CAST(NULL AS STRING)                                                     AS REPAYMENT_ACCOUNT,
    CAST(NULL AS STRING)                                                     AS INT_LIQ_ACCT,
    CAST(NULL AS STRING)                                                     AS PREV_REPAYMENT_DATE,
    CAST(NULL AS DECIMAL(20,4))                                              AS PREV_REPAYMENT_AMT_PR,
    CAST(NULL AS DECIMAL(20,4))                                              AS LD_AMOUNT,
    CAST(NULL AS STRING)                                                     AS NEXT_DATE_IN,
    CAST(NULL AS DECIMAL(20,4))                                              AS NEXT_AMT_IN,
    CAST(NULL AS STRING)                                                     AS LAST_DATE_IN,
    CAST(NULL AS DECIMAL(20,4))                                              AS LAST_AMT_IN,
    1                                                                        AS IS_COMB,
    s.loan_classification                                                    AS T24_LOAN_CLASS_CIF,
    s.loan_classification                                                    AS T24_LN_CLASS
FROM wo_sat s
JOIN comb_hub_raw h ON h.consumer_loan_hashkey = s.consumer_loan_hashkey
LEFT JOIN wo_del d   ON d.consumer_loan_hashkey = s.consumer_loan_hashkey
LEFT JOIN cust cst2  ON CAST(cst2.cif AS STRING)  = CAST(s.customer_id AS STRING)
LEFT JOIN wo_sctr wsc ON CAST(wsc.cif AS STRING)  = CAST(s.customer_id AS STRING)
LEFT JOIN ou ou2     ON CAST(ou2.OU_CODE AS STRING) = CAST(s.branch_code AS STRING)
LEFT JOIN ref_industry  rin  ON CAST(rin.ref_code  AS STRING) = CAST(s.industry_level_3 AS STRING)
LEFT JOIN ref_sector    rse2 ON CAST(rse2.ref_code AS STRING) = CAST(wsc.ip_sctr AS STRING)
LEFT JOIN ref_custgroup rcg2 ON CAST(rcg2.ref_code AS STRING) = CAST(wsc.cust_grp AS STRING)
WHERE d.consumer_loan_hashkey IS NULL
;
