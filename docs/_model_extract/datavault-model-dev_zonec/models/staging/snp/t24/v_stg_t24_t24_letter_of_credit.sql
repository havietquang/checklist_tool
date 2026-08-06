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
    alias = 'v_stg_t24_t24_letter_of_credit',
    materialized = 'view',
    tags = ['t24', 'trade_finance', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_letter_of_credit'),
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
{% set source_table = "t24_letter_of_credit" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_letter_of_credit_classification': ['t_lc_type', 't_operation', 't_category_code', 't_industry_levo', 't_industry_levt', 't_industry_lev1', 't_industry_lev2', 't_industry_lev3', 't_country_code'],
    'hashdiff_letter_of_credit_other': ['t_vmb_class_date', 't_pro_out_amount', 't_advise_thru_custno', 't_acp_coll_exp'],
    'hashdiff_letter_of_credit_party': ['t_applicant_custno', 't_applicant', 't_beneficiary_custno', 't_beneficiary', 't_advise_thru', 't_mt710_57a', 't_advising_bk_custno', 't_advising_bk', 't_applicant_bank', 't_issuing_bank_no', 't_issuing_bank', 't_third_party_custno', 't_third_party', 't_external_reference', 't_old_lc_number', 't_link_ld_ref', 't_port_lim_ref'],
    'hashdiff_letter_of_credit_system': ['t_record_status', 't_inputter', 't_authoriser', 't_date_time'],
    'hashdiff_letter_of_credit_terms': ['t_issue_date', 't_advice_expiry_date', 't_expiry_date', 't_closing_date', 't_presenting_date', 't_tenor', 't_drafts_at', 't_deferred_pay', 't_days', 't_expiry_place'],
    'hashdiff_letter_of_credit_value': ['t_lc_currency', 't_lc_amount', 't_credit_provis_acc', 't_provis_amount', 't_liab_port_amt', 't_percentage_cr_amt', 't_limit_reference', 't_percentage_dr_amt', 't_vmb_ln_class', 't_provis_acc', 't_liability_amt'],
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
{%- set columns = get_columns(source(source_name, source_table)) -%}
{%- set cols_name = [] -%}
{%- for column in columns -%}{%- do cols_name.append(column.name) -%}{%- endfor -%}

{%- set raw_sql %}
select
    --HASH KEY
    {{ hash_column(business_key_cols, source_name) }} as hashkey,

    --ALL COLUMNS FROM SOURCE TABLE
    {% for column in columns %}src.{{ column.name }},
    {% endfor %}

    --HASHDIFF FULL
    {{ hash_column(cols_name, source_name) }} as hashdiff_full,

    --HASHDIFF SATELLITES
    {% for k, v in hashdiff_satellite_dict.items() %}{{ hash_column(v, source_name) }} as {{ k }},
    {% endfor %}

    --TIME & SOURCE COLUMNS
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    '{{ source_name }}' as record_source,
    cast(current_timestamp as timestamp) as load_timestamp

from {{ source(source_name, source_table) }} src
where {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
and id like 'TF%' --Fix MD -> TF 20260518
{%- endset %}

{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=hashdiff_satellite_dict,
    source_event_date_col=source_event_date_col,
    source_event_date_dttype=source_event_date_dttype,
    source_name=source_name,
    raw_sql=raw_sql
) }}
{% endif -%}
