/*
========================================================================
DBT CONFIGURATION GUIDE
========================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['way4'] = filter khi run (dbt run --select tag:way4)
========================================================================
*/

{{ config(
    alias = 'v_stg_way4_acnt_contract',
    materialized = 'view',
    tags = ['way4', 'card', 'contract', 'device', 'product', 'transaction', 'phase2', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('way4'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('ows_acnt_contract'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('amnd_date'),
                            dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name  = "way4" -%}
{% set source_table = "ows_acnt_contract" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_acnt_contract_add_data': ['add_info_01', 'add_info_02', 'add_info_03', 'add_info_04', 'report_address'],
    'hashdiff_account_contract_amount': ['auth_limit_amount', 'base_auth_limit', 'own_balance', 'own_blocked', 'sub_blocked', 'sub_balance', 'total_blocked', 'total_balance', 'shared_blocked', 'shared_balance', 'amount_available', 'acc_scheme__id'],
    'hashdiff_acnt_contract_information': ['contract_number', 'contract_name', 'rbs_number', 'comment_text', 'contr_type', 'contr_subtype__id', 'behavior_group', 'behavior_type', 'serv_pack__id', 'channel', 'curr', 'date_open', 'date_expire', 'last_billing_date', 'next_billing_date', 'contract_level', 'contr_status', 'liab_contract', 'liab_contract_prev', 'billing_contract', 'auth_limit_amount', 'base_auth_limit', 'own_balance', 'own_blocked', 'sub_blocked', 'sub_balance', 'total_blocked', 'total_balance', 'shared_blocked', 'shared_balance', 'amount_available', 'acc_scheme__id'],
    'hashdiff_acnt_contract_other': ['terminal_category', 'f_i', 'service_group', 'old_pack', 'old_scheme', 'parent_product', 'product_prev', 'main_product', 'client_type', 'behavior_type_prev', 'old_curr', 'production_status', 'report_type', 'max_pin_attempts', 'pin_attempts', 'risk_scheme', 'risk_factor', 'risk_factor_prev', 'share_balance', 'is_multycurrency', 'enables_item', 'cycle_length', 'interval_type', 'status_category', 'limit_is_active', 'routing_idt', 'is_ready', 'settlement_type', 'auth_seq_n', 'apply_dt', 'local_version', 'remote_version', 'acnt_contract__id', 'liab_contract', 'product', 'liab_balance', 'liab_blocked', 'card_expire', 'rbs_member_id', 'chip_scheme', 'merchant_id', 'tr_title', 'tr_company', 'tr_country', 'tr_first_nam', 'tr_last_nam', 'tr_sic'],
    'hashdiff_acnt_contract_type': ['pcat', 'con_cat', 'ccat', 'base_relation', 'check_available', 'check_usage', 'ext_data', 'liab_category', 'relation_tag'],
    'hashdiff_acnt_contract_scan': ['last_scan'],
    'hashdiff_card_add_data': ['add_info_01', 'add_info_02', 'add_info_03', 'add_info_04', 'report_address'],
    'hashdiff_card_amount': ['auth_limit_amount', 'base_auth_limit', 'own_balance', 'own_blocked', 'sub_blocked', 'sub_balance', 'total_blocked', 'total_balance', 'shared_blocked', 'shared_balance', 'amount_available', 'acc_scheme__id'],
    'hashdiff_card_information': ['contract_number', 'contract_name', 'tr_title', 'tr_company', 'tr_country', 'tr_first_nam', 'tr_last_nam', 'tr_sic', 'comment_text', 'contr_type', 'contr_subtype__id', 'behavior_group', 'behavior_type', 'serv_pack__id', 'acc_scheme__id', 'channel', 'curr', 'date_open', 'card_expire', 'date_expire', 'last_billing_date', 'next_billing_date', 'last_scan', 'contract_level', 'contr_status'],
    'hashdiff_card_other': ['terminal_category', 'f_i', 'service_group', 'old_pack', 'old_scheme', 'parent_product', 'product_prev', 'main_product', 'client_type', 'behavior_type_prev', 'old_curr', 'production_status', 'rbs_member_id', 'report_type', 'max_pin_attempts', 'pin_attempts', 'risk_scheme', 'chip_scheme', 'risk_factor', 'risk_factor_prev', 'merchant_id', 'share_balance', 'is_multycurrency', 'enables_item', 'cycle_length', 'interval_type', 'status_category', 'limit_is_active', 'routing_idt', 'is_ready', 'settlement_type', 'auth_seq_n', 'apply_dt', 'local_version', 'remote_version'],
    'hashdiff_card_type': ['pcat', 'con_cat', 'ccat', 'base_relation', 'check_available', 'check_usage', 'ext_data', 'liab_category', 'relation_tag'],
    'hashdiff_liability_contract_add_data': ['add_info_01', 'add_info_02', 'add_info_03', 'add_info_04', 'report_address'],
    'hashdiff_liability_contract_amount': ['auth_limit_amount', 'base_auth_limit', 'liab_balance', 'liab_blocked', 'own_balance', 'own_blocked', 'sub_blocked', 'sub_balance', 'total_blocked', 'total_balance', 'shared_blocked', 'shared_balance', 'amount_available', 'acc_scheme__id'],
    'hashdiff_liability_contract_information': ['contract_number', 'contract_name', 'comment_text', 'contr_type', 'contr_subtype__id', 'serv_pack__id', 'acc_scheme__id', 'channel', 'curr', 'date_open', 'date_expire', 'last_billing_date', 'next_billing_date', 'last_scan', 'contract_level', 'contr_status'],
    'hashdiff_liability_contract_type': ['pcat', 'con_cat', 'ccat', 'base_relation', 'check_available', 'check_usage', 'ext_data', 'liab_category', 'relation_tag'],
} -%}

/*
------------------------------------------------------------------------
STAGE MACRO CALL
------------------------------------------------------------------------
Guard `if execute` ngan macro chay luc dbt parse/compile
(tranh loi khi chua co context thuc thi).
Macro `stage()` se sinh ra cau SELECT day du gom:
  - Tat ca cot goc tu source
  - Cot hashkey (hash cua business_key_cols)
  - Cac cot hashdiff theo hashdiff_satellite_dict
  - Cot record_source, source_event_date, load_timestamp
------------------------------------------------------------------------
*/

{% if execute -%}
{{ stage(source_table=source_table
        ,business_key_cols=business_key_cols
        ,hashdiff_satellite_dict=hashdiff_satellite_dict
        ,source_event_date_col=source_event_date_col
        ,source_event_date_dttype=source_event_date_dttype
        ,source_name=source_name)
}}
{% endif -%}
