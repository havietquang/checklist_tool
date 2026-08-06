/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/

{{ config(
    alias = 'v_stg_t24_t24_customer',
    materialized = 'view',
    tags = ['t24', 'entity', 'phase1', 'all', 'zonec', 'bv_zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_customer'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('data_date'),
                            dung lam source_event_date o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name = 't24' -%}
{% set source_table = "t24_customer" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_customer_classification': ['sector', 'industry', 'sub_industry', 'classification', 'cus_type', 'customer_status', 'customer_act', 'cust_group', 'asset_class', 'relation_code', 'ca_man'],
    'hashdiff_customer_contact': ['address', 'ward_1', 'town_country', 'province_1', 'phone_1', 'sms_1', 'off_phone', 'email_1', 'contact_person', 'contact_title', 'status_contact', 'company_name', 'bussiness_addr', 'representative', 'represent_job', 'legal_id_deputy', 'country', 'street', 'add_num', 'ward_2', 'province_2', 'town_country_2', 'sms_2', 'phone_2', 'off_phone_2'],
    'hashdiff_customer_financial_statement': ['total_property', 'total_income', 'sale_income', 'profit_bf_tax', 'plan_revenue', 'commit_revenue', 'commit_date', 'charter_capital', 'net_monthly_in', 'income_source', 'income_by'],
    'hashdiff_customer_information': ['name_1', 'short_name', 'name_2', 'family_name', 'birth_incorp_date', 'gender', 'title', 'nationality', 'residence', 'education_level', 'language', 'cifcontactdate', 'create_date', 'inputter', 'authoriser', 'occupation', 'cu_profession', 'job_title', 'seniority', 'imp_exp_busines', 'marital_status', 'mnemonic', 'target', 'labour_number', 'given_names','date_time'],
    'hashdiff_customer_other': ['post_code', 'customer_liability', 'contact_date', 'province', 'fax_1', 'legacy_ref', 'posting_restrict', 'black_listed', 'curr_company', 'email_2', 'introducer'],
    'hashdiff_customer_kyc': ['legal_doc_name', 'legal_id', 'legal_iss_auth', 'legal_iss_date', 'legal_holder_name', 'legal_exp_date', 'tax_id', 'text', 'ocb_kyc_status'],
    'hashdiff_link_customer_related_customer': ['relation_code'],
}
-%}

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
        ,source_name=source_name
         )
}}
{% endif -%}
