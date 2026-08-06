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
    alias = 'bridge_account',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'entity', 'crb', 'loan', 'account'],
    unique_key = ['crb_hashkey','snapshot_date']
) }}

/*
================================================================================
BRIDGE MODEL DESCRIPTION
================================================================================
  - Bridge nay tong hop quan he giua CRB, account, loan, branch,
    customer va account officer.
  - Model dung DSL bridge_cfg va render qua macro bridge dung chung.
================================================================================
*/
 
{% set bridge_cfg = {
 
    "source_model"        : "hub_crb",
    "base_pk"             : "crb_hashkey",
    "base_date_filter"    : "<=",
    "base_as"             : "hcrb",
    "sts_hub_table"       : "sts_hub_crb",
    "sts_hub_as"          : "sts_hcrb",
    "sts_hub_pk"          : "crb_hashkey",
    "where_clause"        : "substr(hcrb.gl,1,2) in ('41','42','43','44') and sts_hcrb_cte.end_date is null and hcrb.tieukhoan NOT IN ('ROUNDING.ADJUSTMENT','TOTAL')",
 
    "bridge_walk": [
 
        {
            "name"          : "CRB_ACCOUNT",
            "join_type"     : "left",
            "date_filter"   : "<=",
            "link_table"    : "link_crb_account",
            "link_as"       : "link2",
            "link_join_from": "hcrb.crb_hashkey",
            "link_fk"       : "crb_hashkey",
            "link_pk"       : "account_hashkey",
            "hub_table"     : "hub_account",
            "hub_as"        : "hac",
            "hub_pk"        : "account_hashkey"
        },
 
        {
            "name"          : "CRB_LOANS",
            "join_type"     : "left",
            "date_filter"   : "<=",
            "link_table"    : "link_crb_loans",
            "link_as"       : "link1",
            "link_join_from": "hcrb.crb_hashkey",
            "link_fk"       : "crb_hashkey",
            "link_pk"       : "loans_hashkey",
            "hub_table"     : "hub_loans",
            "hub_as"        : "hln",
            "hub_pk"        : "loans_hashkey"
        },
 
        {
            "name"          : "CRB_BRANCH",
            "join_type"     : "left",
            "date_filter"   : "<=",
            "link_table"    : "link_crb_branch",
            "link_as"       : "lnk3",
            "link_join_from": "hcrb.crb_hashkey",
            "link_fk"       : "crb_hashkey",
            "link_pk"       : "branch_hashkey",
            "effsat_table"  : "effsat_link_crb_branch",
            "effsat_hashkey": "link_crb_branch_hashkey",
            "hub_table"     : "hub_branch",
            "hub_as"        : "hbr",
            "hub_pk"        : "branch_hashkey"
        },
 
        {
            "name"          : "CRB_CUSTOMER",
            "join_type"     : "left",
            "date_filter"   : "<=",
            "link_table"    : "link_crb_customer",
            "link_as"       : "lnk4",
            "link_join_from": "hcrb.crb_hashkey",
            "link_fk"       : "crb_hashkey",
            "link_pk"       : "customer_hashkey",
            "effsat_table"  : "effsat_link_crb_customer",
            "effsat_hashkey": "link_crb_customer_hashkey",
            "hub_table"     : "hub_customer",
            "hub_as"        : "hcus",
            "hub_pk"        : "customer_hashkey"
        },
 
        {
            "name"          : "ACCOUNT_DEPT_ACCT_OFFICER",
            "join_type"     : "left",
            "date_filter"   : "<=",
            "link_table"    : "link_account_dept_acct_officer",
            "link_as"       : "ldao",
            "link_join_from": "link2.account_hashkey",
            "link_fk"       : "account_hashkey",
            "link_pk"       : "dept_acct_officer_hashkey",
            "effsat_table"  : "effsat_link_account_dept_acct_officer",
            "effsat_hashkey": "link_account_dept_acct_officer_hashkey",
            "hub_table"     : "hub_acct_officer",
            "hub_as"        : "hao",
            "hub_pk"        : "dept_acct_officer_hashkey"
        }
 
    ],
 
    "select_cols": [
        {"expr": "link2.account_hashkey",                    "as": "account_hashkey"},
        {"expr": "hcrb.crb_hashkey",                         "as": "crb_hashkey"},
        {"expr": "link1.loans_hashkey",                      "as": "loans_hashkey"},
        {"expr": "lnk3.branch_hashkey",                      "as": "branch_hashkey"},
        {"expr": "lnk4.customer_hashkey",                    "as": "customer_hashkey"},
        {"expr": "ldao.dept_acct_officer_hashkey",           "as": "dept_acct_officer_hashkey"},
        {"expr": "hac.business_key",                         "as": "account_business_key"},
        {"expr": "hcrb.gl",                                  "as": "crb_gl"},
        {"expr": "hcrb.tieukhoan",                           "as": "crb_tieukhoan"},
        {"expr": "hln.business_key",                         "as": "loans_business_key"},
        {"expr": "hbr.business_key",                         "as": "branch_business_key"},
        {"expr": "hcus.business_key",                        "as": "customer_business_key"},
        {"expr": "hao.business_key",                         "as": "dept_acct_officer_business_key"}
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
  - bridge_walk         : Danh sach cac buoc join link/hub theo kieu hop.
      + join_type       : Kieu join cua tung buoc (left|inner), mac dinh left.
      + link_table      : Ten bang Link can join.
      + link_as         : Bi danh cho Link de tranh trung ten khi join lap.
      + link_join_from  : Ve trai cua dieu kien join vao Link.
      + link_fk         : Cot FK o bang Link de noi voi bang truoc do.
      + link_pk         : Cot khoa can lay o bang Link de noi sang Hub.
      + hub_table       : Ten bang Hub dich can join.
      + hub_as          : Bi danh cho Hub de tranh trung ten khi join lap.
      + hub_pk          : Cot khoa cua Hub de join voi Link.
  - select_cols         : Danh sach cot output, moi phan tu gom:
      + expr            : Bieu thuc SQL can select.
      + as              : Ten cot output cua model Bridge.
================================================================================
*/ 
{{ bridge(bridge_cfg) }}
 
 
