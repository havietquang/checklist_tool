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
    alias = 'v_stg_t24_t24_payment_due',
    materialized = 'view',
    tags = ['t24', 'loan', 'phase1', 'all', 'zonec', 'bv_zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_payment_due'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('data_date'),
                            dung de gan moc thoi gian su kien cho ban ghi.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name = 't24' -%}
{% set source_table = "t24_payment_due" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_loans_payment_due_classification': ['t_vmb_ln_class', 't_industry_lev1', 't_industry_lev3', 't_contract_grp', 't_ln_class_manual', 't_extend_sch', 't_manual_nab', 't_source_of_fund', 't_doubtful_sta'],
    'hashdiff_loans_payment_due_contract': ['t_limit_reference', 't_orig_limit_ref', 't_link_reference', 't_interest_basis', 't_loan_spread', 't_limit_amount', 't_parameter_record', 't_curr_no', 'notes', 't_bosc_comp_ref'],
    'hashdiff_loans_payment_due_information': ['t_payment_dte_due', 't_final_due_date', 't_start_date', 't_currency', 't_consol_key', 't_payment_amount', 't_status', 't_repayment_acct', 't_extendsch_date'],
    'hashdiff_loans_payment_due_overdue': ['t_pay_type', 't_outstanding_amt', 't_penalty_rate', 't_penalty_spread', 't_pay_amt_orig', 't_pay_amt_outs', 't_total_overdue_amt', 't_tot_ovrdue_type', 't_total_amt_to_repay', 't_tot_od_type_amt', 't_penalty_key'],
    'hashdiff_loans_payment_due_repay': ['t_repaid_status', 't_repayment_date', 't_repay_amt', 't_repaid_amt', 't_new_outs_amt', 't_tot_repay_amt', 't_repayment_ref', 't_repay_type', 't_repay_default', 't_repay_date'],
    'hashdiff_loans_payment_due_detail': ['t_contract_id', 't_customer', 't_co_code', 't_account_officer'],
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
