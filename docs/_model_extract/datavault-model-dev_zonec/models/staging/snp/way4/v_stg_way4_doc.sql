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
    alias = 'v_stg_way4_doc',
    materialized = 'view',
    tags = ['way4', 'transaction', 'phase2', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('way4'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('ows_doc'),
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
{% set source_table = "ows_doc" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_document_classification': ['request_category', 'is_authorization', 'service_class', 'posting_status', 'outward_status', 'message_category', 'trans_type', 'trans_condition', 'trans_cond_attr', 'sec_trans_cond_att', 'requirement'],
    'hashdiff_document_description': ['merchant_id', 'sic_code', 'trans_city', 'trans_country', 'trans_state', 'trans_curr', 'trans_amount', 'trans_details', 'trans_date', 'posting_date', 'settl_curr', 'settl_amount', 'fx_settl_date', 'rec_date', 'reason_code', 'reason_details', 'return_code', 'recons_amount', 'recons_curr', 'sec_trans_date', 'card_expire', 'card_seqv_number', 'add_info', 'comment_text', 'doc__chain__id', 'doc__orig__id', 'doc__summ__id', 'rec_member_id', 'send_member_id'],
    'hashdiff_document_identifiers': ['auth_code', 'source_reg_num', 'ret_ref_number', 'acq_ref_number', 'iss_ref_number', 'ps_ref_number', 'nw_ref_date', 'number_of_sub_s', 'number_in_chain', 'action', 'partition_key', 'change_version', 'synch_tag', 'bin_record'],
    'hashdiff_document_source': ['source_number', 'source_channel', 'source_code', 'source_fee_code', 'source_idt_scheme', 'source_member_id', 'source_spc', 'source_acc_type', 'source_service', 's_cat', 'source_fee_curr', 'source_fee_amount', 'sending_bin'],
    'hashdiff_document_target': ['target_number', 'target_channel', 'target_code', 'target_fee_code', 't_cat', 'target_idt_scheme', 'target_member_id', 'target_bin_id', 'target_spc', 'target_acc_type', 'target_service', 'target_fee_curr', 'target_fee_amount', 'target_country'],
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
