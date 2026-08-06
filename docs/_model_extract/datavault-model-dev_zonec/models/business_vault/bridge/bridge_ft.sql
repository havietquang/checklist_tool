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
    alias = 'bridge_ft',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['t24', 'transaction', 'account', 'entity'],
    unique_key = ['funds_transfer_hashkey','snapshot_date']
) }}

/*
================================================================================
BRIDGE MODEL DESCRIPTION
================================================================================
  - Bridge nay tong hop quan he giua funds_transfer voi account,
    customer, branch va clearing citad cho ca 2 chieu debit/credit.
  - Model dung DSL bridge_cfg va render qua macro bridge dung chung.
================================================================================
*/
{% set bridge_cfg = {
    "source_model": "hub_funds_transfer",
    "base_pk": "funds_transfer_hashkey",
    "base_date_filter": "=",
    "base_as": "hft",
    "base_latest_by_expr": "substring_index(hft.business_key, ';', 1)",
    "base_latest_order_expr": "case when instr(hft.business_key, ';') > 0 then try_cast(substring_index(hft.business_key, ';', -1) as int) else 0 end",
    "bridge_walk": [
        {
            "name": "FT_DEBIT_ACCOUNT",
            "join_type": "left",
            "date_filter": "=",
            "link_table": "link_funds_transfer_debit_account",
            "link_as": "lftda",
            "link_join_from": "hft.funds_transfer_hashkey",
            "link_fk": "funds_transfer_hashkey",
            "link_pk": "account_hashkey",
            "hub_table": "hub_account",
            "hub_as": "had",
            "hub_pk": "account_hashkey"
        },
        {
            "name": "FT_CREDIT_ACCOUNT",
            "join_type": "left",
            "date_filter": "=",
            "link_table": "link_funds_transfer_credit_account",
            "link_as": "lftca",
            "link_join_from": "hft.funds_transfer_hashkey",
            "link_fk": "funds_transfer_hashkey",
            "link_pk": "account_hashkey",
            "hub_table": "hub_account",
            "hub_as": "hac",
            "hub_pk": "account_hashkey"
        },
        {
            "name": "DEBIT_ACCOUNT_CUSTOMER",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "link_account_customer",
            "link_as": "lacd",
            "link_join_from": "lftda.account_hashkey",
            "link_fk": "account_hashkey",
            "link_pk": "customer_hashkey",
            "hub_table": "hub_customer",
            "hub_as": "hcd",
            "hub_pk": "customer_hashkey"
        },
        {
            "name": "CREDIT_ACCOUNT_CUSTOMER",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "link_account_customer",
            "link_as": "lacc",
            "link_join_from": "lftca.account_hashkey",
            "link_fk": "account_hashkey",
            "link_pk": "customer_hashkey",
            "hub_table": "hub_customer",
            "hub_as": "hcc",
            "hub_pk": "customer_hashkey"
        },
        {
            "name": "FT_BRANCH",
            "join_type": "left",
            "date_filter": "=",
            "link_table": "link_funds_transfer_branch",
            "link_as": "lftb",
            "link_join_from": "hft.funds_transfer_hashkey",
            "link_fk": "funds_transfer_hashkey",
            "link_pk": "branch_hashkey",
            "hub_table": "hub_branch",
            "hub_as": "hbr",
            "hub_pk": "branch_hashkey"
        },
        {
            "name": "FT_CLEARING_CITAD",
            "join_type": "left",
            "date_filter": "=",
            "hub_date_filter": "=",
            "link_table": "link_funds_transfer_clearing_citad",
            "link_as": "lftcc",
            "link_join_from": "hft.funds_transfer_hashkey",
            "link_fk": "funds_transfer_hashkey",
            "link_pk": "clearing_citad_hashkey",
            "hub_table": "hub_clearing_citad",
            "hub_as": "hcct",
            "hub_pk": "clearing_citad_hashkey"
        }
    ],
    "select_cols": [
        {"expr": "hft.funds_transfer_hashkey", "as": "funds_transfer_hashkey"},
        {"expr": "lftda.account_hashkey", "as": "account_debit_hashkey"},
        {"expr": "lftca.account_hashkey", "as": "account_credit_hashkey"},
        {"expr": "lacd.customer_hashkey", "as": "customer_debit_hashkey"},
        {"expr": "lacc.customer_hashkey", "as": "customer_credit_hashkey"},
        {"expr": "lftb.branch_hashkey", "as": "branch_hashkey"},
        {"expr": "lftcc.clearing_citad_hashkey", "as": "clearing_citad_hashkey"},
        {"expr": "hft.business_key", "as": "funds_transfer_business_key"},
        {"expr": "had.business_key", "as": "account_debit_business_key"},
        {"expr": "hac.business_key", "as": "account_credit_business_key"},
        {"expr": "hcd.business_key", "as": "customer_debit_business_key"},
        {"expr": "hcc.business_key", "as": "customer_credit_business_key"},
        {"expr": "hbr.business_key", "as": "branch_business_key"},
        {"expr": "hcct.business_key", "as": "clearing_citad_business_key"}
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
{{ bridge_append(bridge_cfg) }}
