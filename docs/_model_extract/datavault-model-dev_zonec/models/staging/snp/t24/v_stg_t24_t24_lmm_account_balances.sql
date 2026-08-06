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
    alias = 'v_stg_t24_t24_lmm_account_balances',
    materialized = 'view',
    tags = ['t24', 'loan', 'phase2', 'phase1', 'all', 'bv_zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_lmm_account_balances'),
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
{% set source_table = "t24_lmm_account_balances" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_lmm_account_balances': ['t_date_from', 't_effective_date', 't_trans_prin_amt', 't_outs_curr_princ', 't_outs_accrued_int', 't_start_period_int', 't_end_period_int', 't_committed_int', 't_princ_int_bal', 't_int_amt_todate', 't_ac_int_rate', 't_ac_int_spread', 't_date_int_acc_to', 't_actual_acc_amt', 't_currency', 't_outs_susp_int'],
    'hashdiff_lmm_account_balances_other': ['t_outs_accrued_comm', 't_last_int_rev_date', 't_next_int_rev_date', 't_prev_int_st_date', 't_int_accr_start', 't_committed_comm'],
    'hashdiff_money_market_lmm_account_balances': ['t_date_from','t_effective_date','t_trans_prin_amt','t_outs_curr_princ','t_outs_accrued_int','t_start_period_int','t_end_period_int','t_committed_int','t_princ_int_bal','t_int_amt_todate','t_ac_int_rate','t_ac_int_spread','t_date_int_acc_to','t_actual_acc_amt','t_currency','t_outs_susp_int','t_outs_accrued_comm','t_last_int_rev_date','t_next_int_rev_date','t_prev_int_st_date','t_int_accr_start','t_committed_comm']
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
with src_cte as (
    select
        LEFT(id, LENGTH(id) - 2) as id,
        * except (id)
    from {{ source(source_name, source_table) }}
    where {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
)
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

from src_cte src
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

