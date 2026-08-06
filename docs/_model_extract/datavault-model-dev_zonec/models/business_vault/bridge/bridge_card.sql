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
    alias = 'bridge_card',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['way4', 'entity', 'contract', 'product'],
    unique_key = ['card_hashkey','snapshot_date']
) }}

/*
================================================================================
BRIDGE MODEL DESCRIPTION
================================================================================
  - Bridge nay tong hop quan he giua card, account contract, client,
    branch va product cua he thong WAY4.
  - Base link la link_account_contract_card va loc active bang
    effsat_link_account_contract_card theo mapping.
  - Model dung DSL bridge_cfg va render qua macro bridge dung chung.
================================================================================
*/
{% set bridge_cfg = {
    "source_model": "link_account_contract_card",
    "base_pk": "link_account_contract_card_hashkey",
    "base_date_filter": "<=",
    "base_as": "lac",
    "base_effsat_table": "effsat_link_account_contract_card",
    "base_effsat_as": "es",
    "base_effsat_hashkey": "link_account_contract_card_hashkey",
    "bridge_walk": [
        {
            "name": "CARD_HUB_ACNT_CONTRACT",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "hub_acnt_contract",
            "link_as": "card_ha",
            "link_join_from": "lac.card_hashkey",
            "link_fk": "acnt_contract_hashkey",
            "link_pk": "acnt_contract_hashkey"
        },
        {
            "name": "ACCOUNT_CONTRACT_HUB_ACNT_CONTRACT",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "hub_acnt_contract",
            "link_as": "account_contract_ha",
            "link_join_from": "lac.account_contract_hashkey",
            "link_fk": "acnt_contract_hashkey",
            "link_pk": "acnt_contract_hashkey"
        },
        {
            "name": "ACNT_CONTRACT_CLIENT",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "link_acnt_contract_client",
            "link_as": "lacc",
            "link_join_from": "lac.card_hashkey",
            "link_fk": "acnt_contract_hashkey",
            "link_pk": "client_hashkey",
            "hub_table": "hub_client",
            "hub_as": "hc",
            "hub_pk": "client_hashkey"
        },
        {
            "name": "CLIENT_CUSTOMER",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "link_client_customer",
            "link_as": "lcc",
            "link_join_from": "lacc.client_hashkey",
            "link_fk": "client_hashkey",
            "link_pk": "customer_hashkey",
            "hub_table": "hub_customer",
            "hub_as": "hcu",
            "hub_pk": "customer_hashkey"
        },
        {
            "name": "ACNT_CONTRACT_BRANCH",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "link_acnt_contract_branch",
            "link_as": "lacb",
            "link_join_from": "lac.card_hashkey",
            "link_fk": "acnt_contract_hashkey",
            "link_pk": "branch_hashkey",
            "hub_table": "hub_branch",
            "hub_as": "hb",
            "hub_pk": "branch_hashkey"
        },
        {
            "name": "ACNT_CONTRACT_PRODUCT",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "link_acnt_contract_product",
            "link_as": "lacp",
            "link_join_from": "lac.card_hashkey",
            "link_fk": "acnt_contract_hashkey",
            "link_pk": "product_hashkey",
            "hub_table": "hub_product",
            "hub_as": "hp",
            "hub_pk": "product_hashkey"
        }
    ],
    "select_cols": [
        {"expr": "lac.card_hashkey", "as": "card_hashkey"},
        {"expr": "lac.account_contract_hashkey", "as": "account_contract_hashkey"},
        {"expr": "lacc.client_hashkey", "as": "client_hashkey"},
        {"expr": "lcc.customer_hashkey", "as": "customer_hashkey"},
        {"expr": "lacb.branch_hashkey", "as": "branch_hashkey"},
        {"expr": "lacp.product_hashkey", "as": "product_hashkey"},
        {"expr": "card_ha.business_key", "as": "card_business_key"},
        {"expr": "account_contract_ha.business_key", "as": "account_contract_business_key"},
        {"expr": "hc.business_key", "as": "client_business_key"},
        {"expr": "hcu.business_key", "as": "customer_business_key"},
        {"expr": "hb.business_key", "as": "branch_business_key"},
        {"expr": "hp.business_key", "as": "product_business_key"}
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
  - base_effsat_table   : Effsat cua base link de lay ban ghi active moi nhat tai snapshot.
  - base_effsat_hashkey : Cot hashkey dung join tu base link sang base effsat.
  - where_clause        : Dieu kien loc bo sung.
  - bridge_walk         : Danh sach cac buoc join theo chuan Link -> Hub.
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
