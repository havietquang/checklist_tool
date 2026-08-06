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
    alias = 'v_stg_t24_t24_security_position',
    materialized = 'view',
    tags = ['t24', 'security', 'phase2', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_security_position'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. Cat ID truoc dau '-' de lay account key.
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
{% set source_table = "t24_security_position" -%}
{% set business_key_cols = ["t_security_number"] -%}
{% set ma_key_expr = "id" -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = 
{
    'hashdiff_security_position': ['ma_key','t_book_cost_sec_ccy','t_cap_amt','t_closing_bal_no_nom','t_cost_invst_bse_ccy','t_cost_invst_ref_ccy','t_cost_invst_sec_ccy','t_date_last_traded','t_depository','t_fin_company','t_gr_bk_cost_sec_ccy','t_gross_cost_sec_ccy','t_held_since','t_income_curr_period','t_issue_date','t_nom_amt_blocked','t_opening_bal_no_nom','t_security_account','t_urlz_ccy_gn_cr_ptf','t_urlz_mrk_gn_cr_ptf','t_val_dat_book_cost','t_value_dat_cost_ref','t_value_dated_cost','t_value_dated_posn','t_ytd_invst_sec_ccy','t_amt_blocked','t_reference_number','t_nominee_code','t_maturity_date','t_interest_rate','t_opn_cost_invst_sec','t_opn_cost_invst_ptf']
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
{%- set columns = get_columns(source(source_name, source_table)) -%}
{%- set cols_name = [] -%}
{%- for column in columns -%}{%- do cols_name.append(column.name) -%}{%- endfor -%}

{%- set raw_sql %}
with source_data as (
    select
        {% for column in columns %}src.{{ column.name }},
        {% endfor %}
        {{ ma_key_expr }} as ma_key
    from {{ source(source_name, source_table) }} src
    where {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
)

select
    --HASH KEY
    {{ hash_column(business_key_cols, source_name) }} as hashkey,

    --ALL COLUMNS FROM SOURCE TABLE
    {% for column in columns %}{{ column.name }},
    {% endfor %}

    --DERIVED BUSINESS KEYS
    ma_key,

    --HASHDIFF FULL
    {{ hash_column(cols_name, source_name) }} as hashdiff_full,

    --HASHDIFF SATELLITES
    {% for k, v in hashdiff_satellite_dict.items() %}{{ hash_column(v, source_name) }} as {{ k }},
    {% endfor %}

    --TIME & SOURCE COLUMNS
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    '{{ source_name }}' as record_source,
    cast(current_timestamp as timestamp) as load_timestamp

from source_data
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
