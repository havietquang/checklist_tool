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
    alias = 'v_stg_t24_t24_md_deal',
    materialized = 'view',
    tags = ['t24', 'trade_finance', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_md_deal'),
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
{% set source_table = "t24_md_deal" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_md_deal_classification': ['t_liquidation_mode', 't_portfolio_no', 't_md_purpose', 't_md_pp_detail', 't_contract_type', 't_industry_levo', 't_industry_levt', 't_industry_lev1', 't_industry_lev2', 't_industry_lev3', 't_inv_status', 't_movement_date'],
    'hashdiff_md_deal_information': ['t_currency', 't_deal_date', 't_value_date', 't_maturity_date', 't_deal_sub_type', 't_category', 't_reference_1', 't_reference_2', 't_text_1', 't_text_2', 't_no_def_exp', 't_local_oversea', 't_ocb_serial_no', 't_ocb_ser_no_main', 't_benef_cust_1', 't_benef_cust_2', 't_ben_address', 't_bank_address', 't_status', 't_advice_expiry_date', 't_country_risk', 't_country_exposure', 't_receiving_bank', 't_overdue_status', 't_charge_account', 't_ocb_charge_acct', 't_fut_real_est', 't_prod_promo', 't_bpm_disb_id', 't_limit_reference'],
    'hashdiff_md_deal_provision': ['t_include_provision', 't_provision', 't_prov_dr_account', 't_prov_percent', 't_prov_amount'],
    'hashdiff_md_deal_system': ['t_inputter', 't_authoriser', 't_date_time', 't_events_processing', 't_limit_upd_reqd', 't_auto_expiry'],
    'hashdiff_md_deal_value': ['t_principal_amount', 't_inv_amount', 't_ocb_online_amt', 't_charge_date', 't_charge_curr', 't_charge_account', 't_charge_code', 't_charge_amt', 't_ocb_avg_fee', 't_ocb_charge', 't_ocb_charge_acct', 't_ocb_col_dt_spec', 't_ocb_coll_period', 't_ocb_estim_due_d', 't_ocb_fee_adjust', 't_ocb_fee_end_dat', 't_ocb_gtee_fee', 't_ocb_gtee_letter', 't_ocb_letter_fee', 't_ocb_m_fee_rate', 't_ocb_mgn_amount', 't_ocb_nonm_fee_r1', 't_ocb_nonm_fee_r2', 't_ocb_nonmargin1', 't_ocb_nonmargin2', 't_ocb_per_collect', 't_ocb_sch_date', 't_ocb_sch_code', 't_ocb_sch_amt', 't_ocb_sch_ccy', 't_ocb_sch_acc', 't_ocb_sch_rem', 't_prin_movement', 't_ocb_secured1', 't_ocb_secured2', 't_ocb_tot_fee'],
    'hashdiff_md_deal_other': ['t_alternate_id','t_csn_amount','t_limit_amount']
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
and id like 'MD%'
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