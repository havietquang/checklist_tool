/*
================================================================================
DBT CONFIGURATION GUIDE
================================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record cua Bridge
skip_matched_step   : true = bo qua record khong doi de tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<ten_nguon>'] = filter khi run (dbt run --select tag:<ten_nguon>)
where_clause        : Dieu kien loc bo sung cho tap du lieu bridge
================================================================================
*/
{{ config(
    alias = 'bridge_loan',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'entity', 'loan', 'crb', 'account'],
    unique_key = ['crb_hashkey','snapshot_date']
) }}

/*
================================================================================
BRIDGE MODEL DESCRIPTION
================================================================================
  - Bridge nay tong hop quan he giua CRB, loan, account, branch,
    customer, officer va saleid.
  - Model dung DSL bridge_cfg va render qua macro bridge dung chung.
================================================================================
*/
{% set bridge_cfg = {
    "source_model": "hub_crb",
    "base_pk": "crb_hashkey",
    "base_date_filter": "<=",
    "base_as": "hcrb",
    "sts_hub_table": "sts_hub_crb",
    "sts_hub_as": "sts_hcrb",
    "sts_hub_pk": "crb_hashkey",
    "where_clause": "hcrb.gl like '2%' and sts_hcrb_cte.end_date is null and substr(hcrb.tieukhoan,1,3) NOT IN ('ROU','TOT')",
    "bridge_walk": [
        {
            "name": "CRB_LOANS",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "link_crb_loans",
            "link_as": "link1",
            "link_join_from": "hcrb.crb_hashkey",
            "link_fk": "crb_hashkey",
            "link_pk": "loans_hashkey",
            "hub_table": "hub_loans",
            "hub_as": "hln",
            "hub_pk": "loans_hashkey"
        },
        {
            "name": "CRB_ACCOUNT",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "link_crb_account",
            "link_as": "link2",
            "link_join_from": "hcrb.crb_hashkey",
            "link_fk": "crb_hashkey",
            "link_pk": "account_hashkey",
            "hub_table": "hub_account",
            "hub_as": "hac",
            "hub_pk": "account_hashkey"
        },
        {
            "name": "CRB_BRANCH",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "link_crb_branch",
            "link_as": "lcb",
            "link_join_from": "hcrb.crb_hashkey",
            "link_fk": "crb_hashkey",
            "link_pk": "branch_hashkey",
            "effsat_table": "effsat_link_crb_branch",
            "effsat_hashkey": "link_crb_branch_hashkey",
            "hub_table": "hub_branch",
            "hub_as": "hbr",
            "hub_pk": "branch_hashkey"
        },
        {
            "name": "CRB_CUSTOMER",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "link_crb_customer",
            "link_as": "lcc",
            "link_join_from": "hcrb.crb_hashkey",
            "link_fk": "crb_hashkey",
            "link_pk": "customer_hashkey",
            "effsat_table": "effsat_link_crb_customer",
            "effsat_hashkey": "link_crb_customer_hashkey",
            "hub_table": "hub_customer",
            "hub_as": "hcus",
            "hub_pk": "customer_hashkey"
        },
        {
            "name": "LOANS_DEPT_ACCT_OFFICER_NVQL",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "link_loans_dept_acct_officer_nvql",
            "link_as": "ldapnvql",
            "link_join_from": "link1.loans_hashkey",
            "link_fk": "loans_hashkey",
            "link_pk": "dept_acct_officer_hashkey",
            "effsat_table": "effsat_link_loans_dept_acct_officer_nvql",
            "effsat_hashkey": "link_loans_dept_acct_officer_nvql_hashkey",
            "hub_table": "hub_acct_officer",
            "hub_as": "hao",
            "hub_pk": "dept_acct_officer_hashkey"
        },
        {
            "name": "CRB_LOANS_PAYMENT_DUE",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "link_crb_loans_payment_due",
            "link_as": "link3",
            "link_join_from": "hcrb.crb_hashkey",
            "link_fk": "crb_hashkey",
            "link_pk": "loans_payment_due_hashkey",
            "hub_table": "hub_loans_payment_due",
            "hub_as": "hlpd",
            "hub_pk": "loans_payment_due_hashkey"
        },
        {
            "name": "LOANS_SALEID",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "link_loans_saleid",
            "link_as": "lls",
            "link_join_from": "link1.loans_hashkey",
            "link_fk": "loans_hashkey",
            "link_pk": "dept_acct_officer_hashkey",
            "effsat_table": "effsat_link_loans_saleid",
            "effsat_hashkey": "link_loans_saleid_hashkey",
            "hub_table": "hub_acct_officer",
            "hub_as": "hao_saleid",
            "hub_pk": "dept_acct_officer_hashkey"
        }
    ],
    "select_cols": [
        {"expr": "hcrb.crb_hashkey", "as": "crb_hashkey"},
        {"expr": "link2.account_hashkey", "as": "acct_hashkey"},
        {"expr": "link1.loans_hashkey", "as": "loans_hashkey"},
        {"expr": "lcb.branch_hashkey", "as": "branch_hashkey"},
        {"expr": "lcc.customer_hashkey", "as": "customer_hashkey"},
        {"expr": "ldapnvql.dept_acct_officer_hashkey", "as": "dept_acct_officer_hashkey"},
        {"expr": "lls.dept_acct_officer_hashkey", "as": "saleid_hashkey"},
        {"expr": "link3.loans_payment_due_hashkey", "as": "loans_payment_due_hashkey"},
        {"expr": "hln.business_key", "as": "loans_business_key"},
        {"expr": "hlpd.business_key", "as": "loans_payment_due_business_key"},
        {"expr": "hac.business_key", "as": "acct_business_key"},
        {"expr": "hcrb.gl", "as": "crb_gl"},
        {"expr": "hcrb.tieukhoan", "as": "crb_tieukhoan"},
        {"expr": "hbr.business_key", "as": "branch_business_key"},
        {"expr": "hcus.business_key", "as": "customer_business_key"},
        {"expr": "hao.business_key", "as": "dept_acct_officer_business_key"},
        {"expr": "hao_saleid.business_key", "as": "saleid_business_key"}
    ]
} %}

/*
================================================================================
BRIDGE MACRO PARAMETERS
================================================================================
  - source_name         : Namespace nguon cua raw_vault. Mac dinh la 'raw_vault'.
  - source_model        : Bang Hub/Link goc cua Bridge.
  - base_pk             : Cot khoa cua bang goc dung de lay moc source_event_date moi nhat.
  - base_as             : Bi danh cua bang goc trong cau query.
  - where_clause        : Dieu kien loc bo sung.
  - bridge_walk         : Danh sach cac buoc join theo chuan Link -> Hub.
      + join_type       : Kieu join cua tung buoc (left|inner), mac dinh left.
      + link_table      : Ten bang Link can join.
      + link_as         : Bi danh cho Link khi can join cung 1 bang nhieu lan.
      + link_join_from  : Ve trai cua dieu kien join vao Link.
      + link_fk         : Cot FK o bang Link de noi voi bang truoc do.
      + link_pk         : Cot khoa can lay o bang Link de noi sang Hub.
      + hub_table       : Ten bang Hub dich can join.
      + hub_as          : Bi danh cho Hub khi can join cung 1 bang nhieu lan.
      + hub_pk          : Cot khoa cua Hub de join voi Link.
  - select_cols         : Danh sach cot output, moi phan tu gom:
      + expr            : Bieu thuc SQL can select.
      + as              : Ten cot output cua model Bridge.
================================================================================
*/
{{ bridge(bridge_cfg) }}
