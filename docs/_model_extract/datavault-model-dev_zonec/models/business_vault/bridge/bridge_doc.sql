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
    alias = 'bridge_doc',
    materialized = 'incremental',
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['way4', 'entity', 'transaction', 'card'],
    unique_key = ['document_fin_hashkey','snapshot_date']
) }}

/*
================================================================================
BRIDGE MODEL DESCRIPTION
================================================================================
  - Bridge nay tong hop quan he giua document, transaction, account contract
    va client trong he thong WAY4.
  - Model dung DSL bridge_cfg va render qua macro bridge dung chung.
================================================================================
*/
{% set bridge_cfg = {
    "source_model": "link_doc_fin_auth",
    "base_pk": "document_fin_hashkey",
    "base_date_filter": "=",
    "base_as": "fin",
    "bridge_walk": [
        {
            "name": "DOCUMENT_BK",
            "join_type": "left",
            "date_filter": "=",
            "link_table": "hub_document",
            "link_as": "hdoc",
            "link_join_from": "fin.document_fin_hashkey",
            "link_fk": "document_hashkey",
            "link_pk": "document_hashkey"
        },
        {
            "name": "DOC_M_TRANSACTION",
            "join_type": "left",
            "date_filter": "=",
            "hub_date_filter": "=",
            "link_table": "link_doc_m_transaction",
            "link_as": "ldmt",
            "link_join_from": "fin.document_fin_hashkey",
            "link_fk": "document_hashkey",
            "link_pk": "m_transaction_hashkey",
            "hub_table": "hub_m_transaction",
            "hub_as": "hmt",
            "hub_pk": "m_transaction_hashkey"
        },
        {
            "name": "DOC_ACNT_CONTRACT",
            "join_type": "left",
            "date_filter": "=",
            "link_table": "link_doc_target_acnt_contract",
            "link_as": "ldtc",
            "link_join_from": "fin.document_fin_hashkey",
            "link_fk": "document_hashkey",
            "link_pk": "acnt_contract_hashkey",
            "hub_table": "hub_acnt_contract",
            "hub_as": "hac",
            "hub_pk": "acnt_contract_hashkey"
        },
        {
            "name": "ACNT_CONTRACT_CLIENT",
            "join_type": "left",
            "date_filter": "<=",
            "link_table": "link_acnt_contract_client",
            "link_as": "lacc",
            "link_join_from": "ldtc.acnt_contract_hashkey",
            "link_fk": "acnt_contract_hashkey",
            "link_pk": "client_hashkey",
            "hub_table": "hub_client",
            "hub_as": "hcl",
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
        }
    ],
    "select_cols": [
        {"expr": "fin.document_fin_hashkey", "as": "document_fin_hashkey"},
        {"expr": "fin.document_auth_hashkey", "as": "document_auth_hashkey"},
        {"expr": "ldmt.m_transaction_hashkey", "as": "m_transaction_hashkey"},
        {"expr": "ldtc.acnt_contract_hashkey", "as": "acnt_contract_hashkey"},
        {"expr": "lacc.client_hashkey", "as": "client_hashkey"},
        {"expr": "lcc.customer_hashkey", "as": "customer_hashkey"},
        {"expr": "hdoc.business_key", "as": "document_business_key"},
        {"expr": "hmt.business_key", "as": "m_transaction_business_key"},
        {"expr": "hac.business_key", "as": "acnt_contract_business_key"},
        {"expr": "hcl.business_key", "as": "client_business_key"},
        {"expr": "hcu.business_key", "as": "customer_business_key"}
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
      + join_type       : Kieu join. Mac dinh la left join.
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
{{ bridge_append(bridge_cfg) }}
