-- Object   : PST_ENTR_FCT
-- Workbook : 072. OCB_GOLD_TCKH_PST_ENTR_FCT_QUANG.xlsx
-- Sheet    : Script
-- PIC      : QUANG
-- Nguon    : tai lieu mapping (input/mapping), KHONG phai code trong src/

USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

DELETE FROM pst_entr_fct
WHERE  CDR_DT_ID = CAST(:DATADT AS INT);

INSERT INTO pst_entr_fct
    (PST_ENTR_ID, AMT_FCY, AMT_LCY, NBR_OF_ITM, CCY_ID, CST_ID, AR_ID, LINE_NBR, TXN_TP_ID, CGY_ID,
     PST_ENTR_ST_ID, INPUTER_ID, APRV_ID, CDR_DT_ID, OU_ID, OU_DW_ID, INPTR_DW_ID, APRV_DW_ID,
     OU_ID_CREATED, AUTO_DIM_ID, CRT_TM, PPN_TM, GL_CDR_DT_ID, INPTR_DW_ID_COM, OU_ID_CREATED_COM)

WITH
user_sts_del AS (
    SELECT user_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sts_hub_user')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY user_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
user_active AS (
    SELECT h.user_hashkey, h.business_key
    FROM      IDENTIFIER(:cleaned || '.raw_vault.hub_user') h
    LEFT JOIN user_sts_del x ON x.user_hashkey = h.user_hashkey
    WHERE  x.user_hashkey IS NULL
      AND h.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY h.user_hashkey, h.business_key
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
account_sts_del AS (
    SELECT account_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sts_hub_account')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY account_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
account_hub AS (
    SELECT account_hashkey, business_key
    FROM   IDENTIFIER(:cleaned || '.raw_vault.hub_account')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY account_hashkey, business_key
),
account_active AS (
    SELECT h.account_hashkey AS ar_dw_id, h.business_key   -- alias khác tên khoá join (X.5)
    FROM      account_hub h
    LEFT JOIN account_sts_del x ON x.account_hashkey = h.account_hashkey
    WHERE  x.account_hashkey IS NULL
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
forex_sts_del AS (
    SELECT forex_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sts_hub_forex')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY forex_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
forex_active AS (
    SELECT h.forex_hashkey, h.business_key
    FROM      IDENTIFIER(:cleaned || '.raw_vault.hub_forex') h
    LEFT JOIN forex_sts_del x ON x.forex_hashkey = h.forex_hashkey
    WHERE  x.forex_hashkey IS NULL
      AND h.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY h.forex_hashkey, h.business_key
),
money_market_sts_del AS (
    SELECT money_market_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sts_hub_money_market')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY money_market_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
money_market_active AS (
    SELECT h.money_market_hashkey, h.business_key
    FROM      IDENTIFIER(:cleaned || '.raw_vault.hub_money_market') h
    LEFT JOIN money_market_sts_del x ON x.money_market_hashkey = h.money_market_hashkey
    WHERE  x.money_market_hashkey IS NULL
      AND h.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY h.money_market_hashkey, h.business_key
),
letter_of_credit_sts_del AS (
    SELECT letter_of_credit_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sts_hub_letter_of_credit')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY letter_of_credit_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
letter_of_credit_active AS (
    SELECT h.letter_of_credit_hashkey, h.business_key
    FROM      IDENTIFIER(:cleaned || '.raw_vault.hub_letter_of_credit') h
    LEFT JOIN letter_of_credit_sts_del x ON x.letter_of_credit_hashkey = h.letter_of_credit_hashkey
    WHERE  x.letter_of_credit_hashkey IS NULL
      AND h.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY h.letter_of_credit_hashkey, h.business_key
),
deposits_sts_del AS (
    SELECT deposit_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sts_hub_deposits')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY deposit_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
deposits_active AS (
    SELECT h.deposit_hashkey, h.business_key
    FROM      IDENTIFIER(:cleaned || '.raw_vault.hub_deposits') h
    LEFT JOIN deposits_sts_del x ON x.deposit_hashkey = h.deposit_hashkey
    WHERE  x.deposit_hashkey IS NULL
      AND h.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY h.deposit_hashkey, h.business_key
),
-- satellite snapshot: lay ban ghi moi nhat tinh den ngay chay
sat_usr_info AS (
    SELECT user_hashkey,
           max_by(t_sign_on_name, source_event_date) AS t_sign_on_name
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_user_information')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY user_hashkey
),
sat_usr_other AS (
    SELECT user_hashkey,
           max_by(t_comp_report,    source_event_date) AS t_comp_report,
           max_by(t_ocb_department, source_event_date) AS t_ocb_department
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_user_other')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY user_hashkey
),
sat_ft_sys AS (
    SELECT funds_transfer_hashkey,
           max_by(t_user_input, source_event_date) AS t_user_input,
           max_by(t_inputter,   source_event_date) AS t_inputter,
           max_by(t_user_auth,  source_event_date) AS t_user_auth,
           max_by(t_authoriser, source_event_date) AS t_authoriser
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_funds_transfer_system')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY funds_transfer_hashkey
),
sat_tlr_other AS (
    SELECT teller_hashkey,
           max_by(t_inputter,   source_event_date) AS t_inputter,
           max_by(t_authoriser, source_event_date) AS t_authoriser
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_teller_other')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY teller_hashkey
),
sat_soa_ft_info AS (
    SELECT soa_cust_ft_hashkey,
           max_by(channel, source_event_date) AS channel
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_soa_cust_ft_information')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY soa_cust_ft_hashkey
),
sat_hdtg_dn AS (
    SELECT serial_no,
           max_by(account_no, source_event_date) AS account_no
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_soa_hdtg_da_nang_information')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY serial_no
),
sat_td_detail AS (
    SELECT hdtg_dn_id,
           max_by(soa_cust_termdeposit_hashkey, source_event_date) AS soa_cust_termdeposit_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_soa_cust_termdeposit_detail')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY hdtg_dn_id
),
sat_td_info AS (
    SELECT soa_cust_termdeposit_hashkey,
           max_by(user_created, source_event_date) AS user_created
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_soa_cust_termdeposit_information')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY soa_cust_termdeposit_hashkey
),
sat_fx_info AS (
    SELECT forex_hashkey,
           max_by(t_deal_date,       source_event_date) AS t_deal_date,
           max_by(t_value_date_buy,  source_event_date) AS t_value_date_buy,
           max_by(t_value_date_sell, source_event_date) AS t_value_date_sell
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_forex_information')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY forex_hashkey
),
sat_mm_info AS (
    SELECT money_market_hashkey,
           max_by(t_maturity_date, source_event_date) AS t_maturity_date
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_money_market_information')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY money_market_hashkey
),
lnk_ft_branch AS (
    SELECT funds_transfer_hashkey,
           max_by(branch_hashkey, source_event_date) AS branch_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_funds_transfer_branch')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY funds_transfer_hashkey
),
lnk_tlr_branch AS (
    SELECT teller_hashkey,
           max_by(branch_hashkey, source_event_date) AS branch_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_teller_branch')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY teller_hashkey
),
lnk_tlr_cust AS (
    SELECT teller_hashkey,
           max_by(customer_hashkey, source_event_date) AS customer_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_teller_customer1')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY teller_hashkey
),
lnk_loans_branch AS (
    SELECT loans_hashkey,
           max_by(branch_hashkey, source_event_date) AS branch_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_loans_branch')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY loans_hashkey
),
usr AS (
    SELECT hu.user_hashkey, hu.business_key AS usr_id, ui.t_sign_on_name,
           uo.t_comp_report, uo.t_ocb_department,
           CASE WHEN hu.business_key LIKE '%COB%'     OR hu.business_key LIKE '%ATM%'
                  OR hu.business_key LIKE '%OSB%'     OR hu.business_key LIKE '%VANHANH%'
                  OR hu.business_key LIKE '%XULY%'    OR hu.business_key LIKE '%BOSC%'
                  OR hu.business_key LIKE '%CASHMNG%' OR hu.business_key LIKE '%SWIFTUSER%'
                  OR hu.business_key LIKE '%CITAD%'   OR hu.business_key LIKE '%DMUSER%'
                  OR hu.business_key LIKE '%ESB%'     OR hu.business_key LIKE '%OFS%'
                THEN 1 ELSE 0 END AS auto_user,
           CASE WHEN uo.t_ocb_department = 'PROJECT DVTD'
                 AND hu.business_key NOT LIKE 'COB%' THEN 1 ELSE 0 END AS user_com
    FROM   user_active hu
           LEFT JOIN sat_usr_info  ui ON ui.user_hashkey = hu.user_hashkey
           LEFT JOIN sat_usr_other uo ON uo.user_hashkey = hu.user_hashkey
),

txn AS (
    SELECT SPLIT_PART(h.business_key,';',1)         AS txn_ref,
           h.funds_transfer_hashkey                 AS ft_hashkey,
           COALESCE(s.t_user_input, s.t_inputter)   AS dvc_id,
           COALESCE(s.t_user_auth , s.t_authoriser) AS txn_aprv,
           lb.branch_hashkey                        AS txn_ou_ip_id,
           CAST(NULL AS STRING)                     AS txn_cst
    FROM   IDENTIFIER(:cleaned || '.raw_vault.hub_funds_transfer') h
           LEFT JOIN sat_ft_sys s  ON s.funds_transfer_hashkey  = h.funds_transfer_hashkey
           LEFT JOIN lnk_ft_branch lb ON lb.funds_transfer_hashkey = h.funds_transfer_hashkey
    WHERE  h.source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
    UNION ALL
    SELECT SPLIT_PART(h.business_key,';',1), CAST(NULL AS STRING),
           NULLIF(SPLIT_PART(o.t_inputter  ,'_',2),''),
           NULLIF(SPLIT_PART(o.t_authoriser,'_',2),''),
           lb.branch_hashkey, lc.customer_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.hub_teller') h
           LEFT JOIN sat_tlr_other o  ON o.teller_hashkey  = h.teller_hashkey
           LEFT JOIN lnk_tlr_branch lb ON lb.teller_hashkey = h.teller_hashkey
           LEFT JOIN lnk_tlr_cust   lc ON lc.teller_hashkey = h.teller_hashkey
    WHERE  h.source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
),

lnk_soa_ft AS (
    SELECT funds_transfer_hashkey,
           max_by(soa_cust_ft_hashkey, source_event_date) AS soa_cust_ft_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_soa_cust_ft_funds_transfer')
    WHERE  source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
    GROUP BY funds_transfer_hashkey
),

chan AS (
    SELECT lsf.funds_transfer_hashkey AS ft_hashkey,
           CASE WHEN UPPER(sfi.channel) = 'TELLER' THEN 'BRANCH' ELSE sfi.channel END AS channel_code
    FROM   lnk_soa_ft lsf
           LEFT JOIN sat_soa_ft_info sfi ON sfi.soa_cust_ft_hashkey = lsf.soa_cust_ft_hashkey
),

comg AS (
    SELECT DISTINCT cg.mvalue AS branch_code, 1 AS is_com
    FROM   IDENTIFIER(:cleaned || '.raw_vault.ref_t24_ocbh_co_group') cg
    WHERE  cg.mvalue IS NOT NULL
),

hdtg AS (
    SELECT hdi.account_no, tdi.user_created AS hdtg_user_created
    FROM   sat_hdtg_dn hdi
           LEFT JOIN sat_td_detail tdd ON tdd.hdtg_dn_id = hdi.serial_no
           LEFT JOIN sat_td_info   tdi ON tdi.soa_cust_termdeposit_hashkey = tdd.soa_cust_termdeposit_hashkey
),

fxmm_noauto AS (
    SELECT h.business_key AS fx_mm_id
    FROM   forex_active h LEFT JOIN sat_fx_info i ON i.forex_hashkey = h.forex_hashkey
    WHERE  i.t_deal_date <> i.t_value_date_buy OR i.t_deal_date <> i.t_value_date_sell
    UNION
    SELECT h.business_key
    FROM   money_market_active h
           LEFT JOIN sat_mm_info i ON i.money_market_hashkey = h.money_market_hashkey
    WHERE  i.t_maturity_date = :DATADT
),

loans_br AS (
    SELECT h.business_key AS contract_no, lb.branch_hashkey AS ar_ou_ip_id
    FROM   loans_active h LEFT JOIN lnk_loans_branch lb ON lb.loans_hashkey = h.loans_hashkey
),

contract_ar AS (
    SELECT business_key AS ref_no, deposit_hashkey           AS ar_hk, 'AZ' AS src FROM deposits_active
    UNION ALL
    SELECT business_key,            loans_hashkey,                     'LD' FROM loans_active
    UNION ALL
    SELECT business_key,            letter_of_credit_hashkey,          'TF' FROM letter_of_credit_active
),
line_mv_hub AS (
    SELECT line_movement_toanhang_hashkey AS lm_hashkey,
           t_line_id
    FROM   IDENTIFIER(:cleaned || '.raw_vault.hub_line_movement_toanhang')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
),
line_mv AS (
    SELECT lm_hashkey, t_line_id FROM line_mv_hub
),
gl_stmt_raw AS (
    SELECT ll.stmt_entry_hashkey AS hk, lm.t_line_id, ll.source_event_date AS gl_dt
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_line_movement_toanhang_stmt_entry') ll
           JOIN line_mv lm ON lm.lm_hashkey = ll.line_movement_toanhang_hashkey
    WHERE  ll.source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
),
gl_stmt AS (
    SELECT hk, t_line_id, gl_dt FROM gl_stmt_raw
),
gl_categ_raw AS (
    SELECT ll.categ_entry_hashkey AS hk, lm.t_line_id, ll.source_event_date AS gl_dt
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_line_movement_toanhang_categ_entry') ll
           JOIN line_mv lm ON lm.lm_hashkey = ll.line_movement_toanhang_hashkey
    WHERE  ll.source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
),
gl_categ AS (
    SELECT hk, t_line_id, gl_dt FROM gl_categ_raw
),
gl_recon_raw AS (
    SELECT ll.re_consol_spec_entry_hashkey AS hk, lm.t_line_id, ll.source_event_date AS gl_dt
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_line_movement_toanhang_re_consol_spec_entry') ll
           JOIN line_mv lm ON lm.lm_hashkey = ll.line_movement_toanhang_hashkey
    WHERE  ll.source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
),
gl_recon AS (
    SELECT hk, t_line_id, gl_dt FROM gl_recon_raw
),

lnk_stmt_branch AS (
    SELECT stmt_entry_hashkey,
           max_by(branch_hashkey, source_event_date) AS branch_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_stmt_entry_branch')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
       OR  (stmt_entry_hashkey IN (SELECT hk FROM gl_stmt WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd'))
            AND source_event_date <= TO_DATE(:DATADT,'yyyyMMdd'))
    GROUP BY stmt_entry_hashkey
),
lnk_stmt_cust AS (
    SELECT stmt_entry_hashkey,
           max_by(customer_hashkey, source_event_date) AS customer_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_stmt_entry_customer')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
       OR  (stmt_entry_hashkey IN (SELECT hk FROM gl_stmt WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd'))
            AND source_event_date <= TO_DATE(:DATADT,'yyyyMMdd'))
    GROUP BY stmt_entry_hashkey
),
lnk_categ_branch AS (
    SELECT categ_entry_hashkey,
           max_by(branch_hashkey, source_event_date) AS branch_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_categ_entry_branch')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
       OR  (categ_entry_hashkey IN (SELECT hk FROM gl_categ WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd'))
            AND source_event_date <= TO_DATE(:DATADT,'yyyyMMdd'))
    GROUP BY categ_entry_hashkey
),
lnk_categ_cust AS (
    SELECT categ_entry_hashkey,
           max_by(customer_hashkey, source_event_date) AS customer_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_categ_entry_customer')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
       OR  (categ_entry_hashkey IN (SELECT hk FROM gl_categ WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd'))
            AND source_event_date <= TO_DATE(:DATADT,'yyyyMMdd'))
    GROUP BY categ_entry_hashkey
),
lnk_recon_branch AS (
    SELECT re_consol_spec_entry_hashkey,
           max_by(branch_hashkey, source_event_date) AS branch_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_re_consol_spec_entry_branch')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
       OR  (re_consol_spec_entry_hashkey IN (SELECT hk FROM gl_recon WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd'))
            AND source_event_date <= TO_DATE(:DATADT,'yyyyMMdd'))
    GROUP BY re_consol_spec_entry_hashkey
),
lnk_recon_cust AS (
    SELECT re_consol_spec_entry_hashkey,
           max_by(customer_hashkey, source_event_date) AS customer_hashkey
    FROM   IDENTIFIER(:cleaned || '.raw_vault.link_re_consol_spec_entry_customer')
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
       OR  (re_consol_spec_entry_hashkey IN (SELECT hk FROM gl_recon WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd'))
            AND source_event_date <= TO_DATE(:DATADT,'yyyyMMdd'))
    GROUP BY re_consol_spec_entry_hashkey
),

stmt_info_raw AS (
    SELECT i.stmt_entry_hashkey, i.source_event_date, i.t_amount_fcy, i.t_amount_lcy,
           i.t_currency, i.t_trans_reference, i.t_narrative,
           i.t_account_number, i.t_master_account
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_stmt_entry_information') i
    WHERE  i.source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
       OR  (i.stmt_entry_hashkey IN (SELECT hk FROM gl_stmt WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd'))
            AND i.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd'))
),
stmt_info AS (
    SELECT stmt_entry_hashkey, source_event_date, t_amount_fcy, t_amount_lcy,
           t_currency, t_trans_reference, t_narrative, t_account_number, t_master_account
    FROM   stmt_info_raw
),
categ_info_raw AS (
    SELECT i.categ_entry_hashkey, i.source_event_date, i.t_amount_fcy, i.t_amount_lcy,
           i.t_currency, i.t_trans_reference, i.t_narrative
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_categ_entry_information') i
    WHERE  i.source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
       OR  (i.categ_entry_hashkey IN (SELECT hk FROM gl_categ WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd'))
            AND i.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd'))
),
categ_info AS (
    SELECT categ_entry_hashkey, source_event_date, t_amount_fcy, t_amount_lcy,
           t_currency, t_trans_reference, t_narrative
    FROM   categ_info_raw
),
recon_info_raw AS (
    SELECT i.re_consol_spec_entry_hashkey, i.source_event_date, i.t_amount_fcy, i.t_amount_lcy,
           i.t_currency, i.t_trans_reference, i.t_narrative, i.t_our_reference
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_re_consol_spec_entry_information') i
    WHERE  i.source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
       OR  (i.re_consol_spec_entry_hashkey IN (SELECT hk FROM gl_recon WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd'))
            AND i.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd'))
),
recon_info AS (
    SELECT re_consol_spec_entry_hashkey, source_event_date, t_amount_fcy, t_amount_lcy,
           t_currency, t_trans_reference, t_narrative, t_our_reference
    FROM   recon_info_raw
),
recon_cls_raw AS (
    SELECT cl.re_consol_spec_entry_hashkey, cl.source_event_date,
           cl.t_transaction_code, cl.t_product_category, cl.t_system_id
    FROM   IDENTIFIER(:cleaned || '.raw_vault.sat_re_consol_spec_entry_classification') cl
    WHERE  cl.source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
       OR  (cl.re_consol_spec_entry_hashkey IN (SELECT hk FROM gl_recon WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd'))
            AND cl.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd'))
),
recon_cls AS (
    SELECT re_consol_spec_entry_hashkey, source_event_date,
           t_transaction_code, t_product_category, t_system_id
    FROM   recon_cls_raw
),

drv_stmt AS (
    SELECT hk FROM gl_stmt WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd')
    UNION
    SELECT stmt_entry_hashkey FROM stmt_info WHERE source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
),
drv_categ AS (
    SELECT hk FROM gl_categ WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd')
    UNION
    SELECT categ_entry_hashkey FROM categ_info WHERE source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
),
drv_recon AS (
    SELECT hk FROM gl_recon WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd')
    UNION
    SELECT re_consol_spec_entry_hashkey FROM recon_info
    WHERE  source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
),

stmt_b AS (
    SELECT h.stmt_entry_hashkey                                            AS PST_ENTR_ID,
           CASE WHEN i.t_amount_fcy IS NULL AND i.t_currency = 'VND'
                THEN i.t_amount_lcy ELSE i.t_amount_fcy END                AS AMT_FCY,
           i.t_amount_lcy                                                  AS AMT_LCY,
           i.t_currency                                                    AS CCY_ID,
           lc.customer_hashkey                                             AS CST_ENTRY,
           COALESCE(ham.ar_dw_id, ha.ar_dw_id)                             AS AR_ID,
           CAST(SPLIT_PART(g.t_line_id,'-',2) AS INT)                      AS LINE_NBR,
           regexp_replace(CAST(cl.t_transaction_code AS STRING),'\\.0+$','') AS TXN_TP_CODE,
           cl.t_product_category                                           AS CGY_ID,
           CASE WHEN a.t_record_status = 'REVE' THEN 105200003 ELSE 105200001 END AS PST_ENTR_ST_ID,
           a.t_inputter, a.t_authoriser,
           CAST(DATE_FORMAT(COALESCE(g.gl_dt, i.source_event_date),'yyyyMMdd') AS INT) AS CDR_DT_ID,
           hb.business_key                                                 AS OU_ID,
           lb.branch_hashkey                                               AS OU_DW_ID,
           i.t_trans_reference, i.t_narrative,
           i.t_account_number                                              AS ACCT_NO,
           SPLIT_PART(g.t_line_id,'-',2)                                   AS GL,
           SUBSTR(g.t_line_id, 20, 8)                                      AS GL_CDR_DT_ID,
           'A'                                                             AS ENTRY_TYPE,
           SPLIT_PART(i.t_trans_reference,'\\\\',1)                          AS TXN_KEY,
           SUBSTR(i.t_trans_reference,1,12)                                AS FXMM_KEY,
           CASE WHEN INSTR(i.t_trans_reference,'LD') > 0
                THEN SUBSTR(i.t_trans_reference, INSTR(i.t_trans_reference,'LD'), 12)
                ELSE i.t_trans_reference END                               AS TXN_NO
    FROM   drv_stmt dv
           JOIN      stmt_info i  ON i.stmt_entry_hashkey  = dv.hk
           LEFT JOIN (SELECT DISTINCT stmt_entry_hashkey FROM IDENTIFIER(:cleaned || '.raw_vault.hub_stmt_entry')
                      WHERE source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
                         OR (stmt_entry_hashkey IN (SELECT hk FROM gl_stmt WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd'))
                             AND source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')))                h  ON h.stmt_entry_hashkey  = i.stmt_entry_hashkey
           LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.sat_stmt_entry_classification') cl ON cl.stmt_entry_hashkey = i.stmt_entry_hashkey
                                                     AND cl.source_event_date = i.source_event_date
                 AND cl.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
           LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.sat_stmt_entry_audit')          a  ON a.stmt_entry_hashkey  = i.stmt_entry_hashkey
                                                     AND a.source_event_date  = i.source_event_date
                 AND a.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
           LEFT JOIN lnk_stmt_branch lb ON lb.stmt_entry_hashkey = i.stmt_entry_hashkey
           LEFT JOIN branch_active                    hb ON hb.branch_hashkey     = lb.branch_hashkey
           LEFT JOIN lnk_stmt_cust   lc ON lc.stmt_entry_hashkey = i.stmt_entry_hashkey
           LEFT JOIN account_active                   ha ON ha.business_key       = i.t_account_number
           LEFT JOIN account_active                   ham ON ham.business_key      = i.t_master_account
           LEFT JOIN gl_stmt                       g  ON g.hk                  = i.stmt_entry_hashkey
    WHERE  COALESCE(g.gl_dt, i.source_event_date) = TO_DATE(:DATADT,'yyyyMMdd')
),

categ_b AS (
    SELECT h2.categ_entry_hashkey                                          AS PST_ENTR_ID,
           CASE WHEN i2.t_amount_fcy IS NULL AND i2.t_currency = 'VND'
                THEN i2.t_amount_lcy ELSE i2.t_amount_fcy END              AS AMT_FCY,
           i2.t_amount_lcy                                                 AS AMT_LCY,
           i2.t_currency                                                   AS CCY_ID,
           lc2.customer_hashkey                                            AS CST_ENTRY,
           sha2(
               CONCAT_WS('$',
                   COALESCE(UPPER(TRIM(CAST(cl2.t_pl_category AS STRING))), ''),
                   COALESCE(UPPER(TRIM(hb2.business_key)), ''),
                   COALESCE(UPPER(TRIM(i2.t_currency)), '')
               ), 256
           )                                                               AS AR_ID,
           CAST(SPLIT_PART(g.t_line_id,'-',2) AS INT)                      AS LINE_NBR,
           regexp_replace(CAST(cl2.t_transaction_code AS STRING),'\\.0+$','') AS TXN_TP_CODE,
           cl2.t_product_category                                          AS CGY_ID,
           CAST(NULL AS INT)                                               AS PST_ENTR_ST_ID,
           a2.t_inputter, a2.t_authoriser,
           CAST(DATE_FORMAT(COALESCE(g.gl_dt, i2.source_event_date),'yyyyMMdd') AS INT) AS CDR_DT_ID,
           hb2.business_key                                                AS OU_ID,
           lb2.branch_hashkey                                              AS OU_DW_ID,
           i2.t_trans_reference, i2.t_narrative,
           CAST(NULL AS STRING)                                            AS ACCT_NO,
           SPLIT_PART(g.t_line_id,'-',2)                                   AS GL,
           SUBSTR(g.t_line_id, 20, 8)                                      AS GL_CDR_DT_ID,
           'P'                                                             AS ENTRY_TYPE,
           SPLIT_PART(i2.t_trans_reference,'\\\\',1)                         AS TXN_KEY,
           SUBSTR(i2.t_trans_reference,1,12)                               AS FXMM_KEY,
           CASE WHEN INSTR(i2.t_trans_reference,'LD') > 0
                THEN SUBSTR(i2.t_trans_reference, INSTR(i2.t_trans_reference,'LD'), 12)
                ELSE i2.t_trans_reference END                              AS TXN_NO
    FROM   drv_categ dv
           JOIN      categ_info i2  ON i2.categ_entry_hashkey  = dv.hk
           LEFT JOIN (SELECT DISTINCT categ_entry_hashkey FROM IDENTIFIER(:cleaned || '.raw_vault.hub_categ_entry')
                      WHERE source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
                         OR (categ_entry_hashkey IN (SELECT hk FROM gl_categ WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd'))
                             AND source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')))                h2  ON h2.categ_entry_hashkey  = i2.categ_entry_hashkey
           LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.sat_categ_entry_classification') cl2 ON cl2.categ_entry_hashkey = i2.categ_entry_hashkey
                                                       AND cl2.source_event_date   = i2.source_event_date
                 AND cl2.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
           LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.sat_categ_entry_audit')          a2  ON a2.categ_entry_hashkey  = i2.categ_entry_hashkey
                                                       AND a2.source_event_date    = i2.source_event_date
                 AND a2.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
           LEFT JOIN lnk_categ_branch lb2 ON lb2.categ_entry_hashkey = i2.categ_entry_hashkey
           LEFT JOIN branch_active                     hb2 ON hb2.branch_hashkey      = lb2.branch_hashkey
           LEFT JOIN lnk_categ_cust   lc2 ON lc2.categ_entry_hashkey = i2.categ_entry_hashkey
           LEFT JOIN gl_categ                       g   ON g.hk                    = i2.categ_entry_hashkey
    WHERE  COALESCE(g.gl_dt, i2.source_event_date) = TO_DATE(:DATADT,'yyyyMMdd')
),

recon_key AS (
    SELECT i3.re_consol_spec_entry_hashkey AS hk,
           CASE WHEN cl3.t_system_id = 'AC' AND LEFT(i3.t_our_reference,2) = 'AZ'
                     THEN SUBSTR(i3.t_our_reference,4,16)
                WHEN cl3.t_system_id IN ('LD','PD')
                     THEN SUBSTR(i3.t_our_reference, INSTR(i3.t_our_reference,'LD'), 12)
                WHEN LEFT(i3.t_our_reference,2) = 'TF'
                     THEN LEFT(i3.t_our_reference,12)
                ELSE i3.t_our_reference END AS ref_no
    FROM   recon_info i3
           LEFT JOIN recon_cls cl3
                  ON cl3.re_consol_spec_entry_hashkey = i3.re_consol_spec_entry_hashkey
                 AND cl3.source_event_date           = i3.source_event_date
                 AND cl3.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
),
reconsol_b AS (
    SELECT h3.re_consol_spec_entry_hashkey                                 AS PST_ENTR_ID,
           CASE WHEN i3.t_amount_fcy IS NULL AND i3.t_currency = 'VND'
                THEN i3.t_amount_lcy ELSE i3.t_amount_fcy END              AS AMT_FCY,
           i3.t_amount_lcy                                                 AS AMT_LCY,
           i3.t_currency                                                   AS CCY_ID,
           lc3.customer_hashkey                                            AS CST_ENTRY,
           car.ar_hk                                                       AS AR_ID,
           CAST(SPLIT_PART(g.t_line_id,'-',2) AS INT)                      AS LINE_NBR,
           regexp_replace(CAST(cl3.t_transaction_code AS STRING),'\\.0+$','') AS TXN_TP_CODE,
           cl3.t_product_category                                          AS CGY_ID,
           CASE WHEN a3.t_record_status = 'REVE' THEN 105200003 ELSE 105200001 END AS PST_ENTR_ST_ID,
           a3.t_inputter, a3.t_authoriser,
           CAST(DATE_FORMAT(COALESCE(g.gl_dt, i3.source_event_date),'yyyyMMdd') AS INT) AS CDR_DT_ID,
           hb3.business_key                                                AS OU_ID,
           lb3.branch_hashkey                                              AS OU_DW_ID,
           i3.t_trans_reference, i3.t_narrative,
           CAST(NULL AS STRING)                                            AS ACCT_NO,
           SPLIT_PART(g.t_line_id,'-',2)                                   AS GL,
           SUBSTR(g.t_line_id, 20, 8)                                      AS GL_CDR_DT_ID,
           'R'                                                             AS ENTRY_TYPE,
           SPLIT_PART(i3.t_trans_reference,'\\\\',1)                         AS TXN_KEY,
           SUBSTR(i3.t_trans_reference,1,12)                               AS FXMM_KEY,
           CASE WHEN INSTR(i3.t_trans_reference,'LD') > 0
                THEN SUBSTR(i3.t_trans_reference, INSTR(i3.t_trans_reference,'LD'), 12)
                ELSE i3.t_trans_reference END                              AS TXN_NO
    FROM   drv_recon dv
           JOIN      recon_info i3
                  ON i3.re_consol_spec_entry_hashkey = dv.hk
           LEFT JOIN (SELECT DISTINCT re_consol_spec_entry_hashkey FROM IDENTIFIER(:cleaned || '.raw_vault.hub_re_consol_spec_entry')
                      WHERE source_event_date = TO_DATE(:DATADT,'yyyyMMdd')
                         OR (re_consol_spec_entry_hashkey IN (SELECT hk FROM gl_recon WHERE gl_dt = TO_DATE(:DATADT,'yyyyMMdd'))
                             AND source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')))                h3
                  ON h3.re_consol_spec_entry_hashkey = i3.re_consol_spec_entry_hashkey
           LEFT JOIN recon_cls cl3
                  ON cl3.re_consol_spec_entry_hashkey = i3.re_consol_spec_entry_hashkey
                 AND cl3.source_event_date           = i3.source_event_date
                 AND cl3.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
           LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.sat_re_consol_spec_entry_audit')          a3
                  ON a3.re_consol_spec_entry_hashkey  = i3.re_consol_spec_entry_hashkey
                 AND a3.source_event_date            = i3.source_event_date
                 AND a3.source_event_date <= TO_DATE(:DATADT,'yyyyMMdd')
           LEFT JOIN lnk_recon_branch lb3
                  ON lb3.re_consol_spec_entry_hashkey = i3.re_consol_spec_entry_hashkey
           LEFT JOIN branch_active                              hb3 ON hb3.branch_hashkey = lb3.branch_hashkey
           LEFT JOIN lnk_recon_cust   lc3
                  ON lc3.re_consol_spec_entry_hashkey = i3.re_consol_spec_entry_hashkey
           LEFT JOIN gl_recon                                g   ON g.hk = i3.re_consol_spec_entry_hashkey
           LEFT JOIN recon_key                               rk  ON rk.hk = i3.re_consol_spec_entry_hashkey
           LEFT JOIN contract_ar                             car ON car.ref_no = rk.ref_no
    WHERE  COALESCE(g.gl_dt, i3.source_event_date) = TO_DATE(:DATADT,'yyyyMMdd')
),

base AS (
    SELECT PST_ENTR_ID, AMT_FCY, AMT_LCY, CCY_ID, CST_ENTRY, AR_ID, LINE_NBR, TXN_TP_CODE, CGY_ID,
           PST_ENTR_ST_ID, t_inputter, t_authoriser, CDR_DT_ID, OU_ID, OU_DW_ID, t_trans_reference,
           t_narrative, ACCT_NO, GL, GL_CDR_DT_ID, ENTRY_TYPE, TXN_KEY, FXMM_KEY, TXN_NO
    FROM   stmt_b
    UNION ALL
    SELECT PST_ENTR_ID, AMT_FCY, AMT_LCY, CCY_ID, CST_ENTRY, AR_ID, LINE_NBR, TXN_TP_CODE, CGY_ID,
           PST_ENTR_ST_ID, t_inputter, t_authoriser, CDR_DT_ID, OU_ID, OU_DW_ID, t_trans_reference,
           t_narrative, ACCT_NO, GL, GL_CDR_DT_ID, ENTRY_TYPE, TXN_KEY, FXMM_KEY, TXN_NO
    FROM   categ_b
    UNION ALL
    SELECT PST_ENTR_ID, AMT_FCY, AMT_LCY, CCY_ID, CST_ENTRY, AR_ID, LINE_NBR, TXN_TP_CODE, CGY_ID,
           PST_ENTR_ST_ID, t_inputter, t_authoriser, CDR_DT_ID, OU_ID, OU_DW_ID, t_trans_reference,
           t_narrative, ACCT_NO, GL, GL_CDR_DT_ID, ENTRY_TYPE, TXN_KEY, FXMM_KEY, TXN_NO
    FROM   reconsol_b
),

enr AS (
    SELECT b.PST_ENTR_ID, b.AMT_FCY, b.AMT_LCY, b.CCY_ID, b.CST_ENTRY, b.AR_ID, b.LINE_NBR,
           b.TXN_TP_CODE, b.CGY_ID, b.PST_ENTR_ST_ID, b.t_inputter, b.t_authoriser, b.CDR_DT_ID,
           b.OU_ID, b.OU_DW_ID, b.t_trans_reference, b.t_narrative, b.ACCT_NO, b.GL, b.GL_CDR_DT_ID,
           b.ENTRY_TYPE, b.TXN_KEY, b.FXMM_KEY, b.TXN_NO,
           t.dvc_id, t.txn_aprv, t.txn_ou_ip_id, t.txn_cst, t.ft_hashkey,
           ch.channel_code,
           CASE WHEN fx.fx_mm_id IS NOT NULL THEN 1 ELSE 0 END AS is_fx_mm_noauto,
           lo.ar_ou_ip_id,
           hd.hdtg_user_created
    FROM   base b
           LEFT JOIN txn         t  ON t.txn_ref      = b.TXN_KEY
           LEFT JOIN chan        ch ON ch.ft_hashkey  = t.ft_hashkey
           LEFT JOIN fxmm_noauto fx ON fx.fx_mm_id    = b.FXMM_KEY
           LEFT JOIN loans_br    lo ON lo.contract_no = b.TXN_NO
           LEFT JOIN hdtg        hd ON hd.account_no  = b.ACCT_NO
),
calc AS (
    SELECT e.PST_ENTR_ID, e.AMT_FCY, e.AMT_LCY, e.CCY_ID, e.CST_ENTRY, e.AR_ID, e.LINE_NBR,
           e.TXN_TP_CODE, e.CGY_ID, e.PST_ENTR_ST_ID, e.t_inputter, e.t_authoriser, e.CDR_DT_ID,
           e.OU_ID, e.OU_DW_ID, e.t_trans_reference, e.t_narrative, e.ACCT_NO, e.GL, e.GL_CDR_DT_ID,
           e.ENTRY_TYPE, e.TXN_KEY, e.FXMM_KEY, e.TXN_NO, e.dvc_id, e.txn_aprv, e.txn_ou_ip_id,
           e.txn_cst, e.ft_hashkey, e.channel_code, e.is_fx_mm_noauto, e.ar_ou_ip_id,
           e.hdtg_user_created,
           CASE WHEN e.hdtg_user_created IS NOT NULL THEN e.hdtg_user_created
                WHEN LEFT(e.dvc_id,1) = 'T'          THEN e.dvc_id
                ELSE COALESCE(NULLIF(SPLIT_PART(e.t_inputter,'_',2),''), e.t_inputter) END AS INPUTER_ID,
           CASE WHEN LEFT(e.dvc_id,1) = 'T'          THEN e.txn_aprv
                ELSE COALESCE(NULLIF(SPLIT_PART(e.t_authoriser,'_',2),''), e.t_authoriser) END AS APRV_ID,
           COALESCE(e.txn_cst, e.CST_ENTRY)                                        AS CST_ID,
           CASE WHEN LEFT(e.TXN_NO,2) IN ('FT','TT') THEN COALESCE(e.txn_ou_ip_id, e.OU_DW_ID)
                WHEN LEFT(e.TXN_NO,2) = 'LD'         THEN COALESCE(e.ar_ou_ip_id, e.OU_DW_ID)
                ELSE e.OU_DW_ID END                                                AS OU_DW_ID_COM
    FROM   enr e
),
fin AS (
    SELECT c.PST_ENTR_ID, c.AMT_FCY, c.AMT_LCY, c.CCY_ID, c.CST_ENTRY, c.AR_ID, c.LINE_NBR,
           c.TXN_TP_CODE, c.CGY_ID, c.PST_ENTR_ST_ID, c.t_inputter, c.t_authoriser, c.CDR_DT_ID,
           c.OU_ID, c.OU_DW_ID, c.t_trans_reference, c.t_narrative, c.ACCT_NO, c.GL, c.GL_CDR_DT_ID,
           c.ENTRY_TYPE, c.TXN_KEY, c.FXMM_KEY, c.TXN_NO, c.dvc_id, c.txn_aprv, c.txn_ou_ip_id,
           c.txn_cst, c.ft_hashkey, c.channel_code, c.is_fx_mm_noauto, c.ar_ou_ip_id,
           c.hdtg_user_created, c.INPUTER_ID, c.APRV_ID, c.CST_ID, c.OU_DW_ID_COM,
           ui.user_hashkey AS INPTR_DW_ID, ui.auto_user, ui.user_com, ui.t_comp_report,
           ua.user_hashkey AS APRV_DW_ID,
           CASE WHEN cg.is_com = 1 THEN 1 ELSE 0 END AS is_com,
           CASE WHEN c.TXN_TP_CODE IN ('182','183')                                          THEN 1
                WHEN c.TXN_TP_CODE = '381' AND SUBSTR(CAST(c.LINE_NBR AS STRING),1,2) <> '10' THEN 1
                WHEN c.TXN_TP_CODE IN ('366','367','494')
                     AND c.t_narrative NOT LIKE 'EARLY REDEMPTION%'
                     AND c.t_narrative NOT LIKE 'PRE CLOSURE%'                               THEN 1
                WHEN c.ENTRY_TYPE = 'P'
                     AND LEFT(c.t_trans_reference,2) NOT IN ('TT','FT','LD','PD','TF','DC','FX','MM','MD') THEN 1
                WHEN LEFT(c.t_trans_reference,2) <> 'TF' AND c.ENTRY_TYPE = 'R'
                     AND (LEFT(c.INPUTER_ID,1) <> 'T'
                          OR (LEFT(c.INPUTER_ID,1) = 'T'
                              AND LEFT(c.GL,1) NOT IN ('2','7') AND LEFT(c.GL,2) <> '92'
                              AND LEFT(c.GL,3) NOT IN ('394','941','994','996')))            THEN 1
                WHEN LEFT(c.t_trans_reference,2) = 'TF' AND c.GL = '9995'                     THEN 1
                ELSE 0 END                                                          AS auto_src
    FROM   calc c
           LEFT JOIN usr  ui ON ui.usr_id = c.INPUTER_ID
           LEFT JOIN usr  ua ON ua.usr_id = c.APRV_ID
           LEFT JOIN comg cg ON cg.branch_code = c.OU_ID
),
flg AS (
    SELECT f.PST_ENTR_ID, f.AMT_FCY, f.AMT_LCY, f.CCY_ID, f.CST_ENTRY, f.AR_ID, f.LINE_NBR,
           f.TXN_TP_CODE, f.CGY_ID, f.PST_ENTR_ST_ID, f.t_inputter, f.t_authoriser, f.CDR_DT_ID,
           f.OU_ID, f.OU_DW_ID, f.t_trans_reference, f.t_narrative, f.ACCT_NO, f.GL, f.GL_CDR_DT_ID,
           f.ENTRY_TYPE, f.TXN_KEY, f.FXMM_KEY, f.TXN_NO, f.dvc_id, f.txn_aprv, f.txn_ou_ip_id,
           f.txn_cst, f.ft_hashkey, f.channel_code, f.is_fx_mm_noauto, f.ar_ou_ip_id,
           f.hdtg_user_created, f.INPUTER_ID, f.APRV_ID, f.CST_ID, f.OU_DW_ID_COM, f.INPTR_DW_ID,
           f.auto_user, f.user_com, f.t_comp_report, f.APRV_DW_ID, f.is_com, f.auto_src,
           CASE WHEN f.is_fx_mm_noauto = 1                                     THEN 0
                WHEN f.channel_code IS NOT NULL AND f.channel_code <> 'BRANCH' THEN 1
                WHEN f.auto_src = 0 AND LEFT(f.GL,3) IN ('994','996')          THEN 0
                WHEN COALESCE(f.auto_user,0) = 1                               THEN 1
                ELSE f.auto_src END                                             AS AUTO_DIM_ID
    FROM   fin f
)

SELECT
    g.PST_ENTR_ID, g.AMT_FCY, g.AMT_LCY,
    CAST(1 AS SMALLINT)                                          AS NBR_OF_ITM,
    g.CCY_ID, g.CST_ID, g.AR_ID, g.LINE_NBR,
    g.TXN_TP_CODE                                                AS TXN_TP_ID,
    COALESCE(CAST(g.CGY_ID AS INT), 0)                           AS CGY_ID,
    g.PST_ENTR_ST_ID, g.INPUTER_ID, g.APRV_ID, g.CDR_DT_ID, g.OU_ID, g.OU_DW_ID,
    CASE WHEN (COALESCE(g.user_com,0) = 1
               OR (g.is_com = 1 AND LEFT(g.INPUTER_ID,3) = 'COB'))
              AND g.AUTO_DIM_ID = 0 THEN NULL ELSE g.INPTR_DW_ID END        AS INPTR_DW_ID,
    g.APRV_DW_ID,
    CASE WHEN (COALESCE(g.user_com,0) = 1
               OR (g.is_com = 1 AND LEFT(g.INPUTER_ID,3) = 'COB'))
              AND g.AUTO_DIM_ID = 0 THEN NULL
         WHEN LEFT(g.t_trans_reference,2) NOT IN ('FT','TT','DC','FX','AZ','TF','MM','PD','LD','SC')
              AND LEFT(g.t_trans_reference,17) <> 'ONLINE.AC.CLOSURE'       THEN g.OU_DW_ID
         WHEN hbu.branch_hashkey IS NOT NULL THEN
              CASE WHEN LEFT(g.t_trans_reference,2) = 'LD'                  THEN hbu.branch_hashkey
                   WHEN COALESCE(g.auto_user,0) = 1                         THEN g.OU_DW_ID
                   ELSE hbu.branch_hashkey END
         WHEN g.txn_ou_ip_id IS NOT NULL                                    THEN g.txn_ou_ip_id
         ELSE g.OU_DW_ID END                                                AS OU_ID_CREATED,
    g.AUTO_DIM_ID,
    current_timestamp()                                          AS CRT_TM,
    current_timestamp()                                          AS PPN_TM,
    g.GL_CDR_DT_ID,
    CASE WHEN (COALESCE(g.user_com,0) = 1
               OR (g.is_com = 1 AND LEFT(g.INPUTER_ID,3) = 'COB'))
              AND g.AUTO_DIM_ID = 0 THEN g.INPTR_DW_ID
         ELSE NULL END                                              AS INPTR_DW_ID_COM,
    CASE WHEN (COALESCE(g.user_com,0) = 1
               OR (g.is_com = 1 AND LEFT(g.INPUTER_ID,3) = 'COB'))
              AND g.AUTO_DIM_ID = 0 THEN g.OU_DW_ID_COM
         ELSE NULL END                                              AS OU_ID_CREATED_COM
FROM   flg g
       LEFT JOIN branch_active hbu ON hbu.business_key = g.t_comp_report;