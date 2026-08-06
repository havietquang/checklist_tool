/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record (thuong: hub_hashkey + hashdiff)
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/

{{ config(
    alias = 'sat_money_market_lmm_account_balances',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['money_market_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'money_market', 'phase1', 'all']
) }}

/*
========================================================================
SATELLITE MACRO PARAMETERS
========================================================================
  - source_name         : Ten he thong nguon, dung de tao gia tri cho cot `record_source`.
  - source_table        : Ten bang nghiep vu o he thong nguon.
  - hashdiff_col        : Ten cot hashdiff duoc tinh trong model nay.
  - hub_hashkey         : Ten khoa hash dung de lien ket ve bang Hub.
  - source_model        : Model staging lam nguon de doc du lieu.
  - raw_sql (optional)  : Cau SQL tu viet trong truong hop logic phuc tap hoac dac biet.
========================================================================
*/

{% set source_name = 't24' %}
{% set source_table = 't24_lmm_account_balances' %}
{% set cols_name = ['a.t_date_from', 'a.t_effective_date', 'a.t_trans_prin_amt', 'a.t_outs_curr_princ', 'a.t_outs_accrued_int', 'a.t_start_period_int', 'a.t_end_period_int', 'a.t_committed_int', 'a.t_princ_int_bal', 'a.t_int_amt_todate', 'a.t_ac_int_rate', 'a.t_ac_int_spread', 'a.t_date_int_acc_to', 'a.t_actual_acc_amt', 'a.t_currency', 'a.t_outs_susp_int', 'a.t_outs_accrued_comm', 'a.t_last_int_rev_date', 'a.t_next_int_rev_date', 'a.t_prev_int_st_date', 'a.t_int_accr_start', 'a.t_committed_comm'] %}
{% set hashdiff_col = hash_column(cols_name, source_name) %}
{% set hub_hashkey = 'money_market_hashkey' %}
{% set source_model = 'v_stg_t24_t24_lmm_account_balances' %}

{% set raw_sql -%}
SELECT
    a.hashkey AS money_market_hashkey,
    {{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(cast('{{source_name}}' as string), '__', '{{source_table}}') AS record_source,
    a.t_date_from AS t_date_from,
    a.t_effective_date AS t_effective_date,
    a.t_trans_prin_amt AS t_trans_prin_amt,
    a.t_outs_curr_princ AS t_outs_curr_princ,
    a.t_outs_accrued_int AS t_outs_accrued_int,
    a.t_start_period_int AS t_start_period_int,
    a.t_end_period_int AS t_end_period_int,
    a.t_committed_int AS t_committed_int,
    a.t_princ_int_bal AS t_princ_int_bal,
    a.t_int_amt_todate AS t_int_amt_todate,
    a.t_ac_int_rate AS t_ac_int_rate,
    a.t_ac_int_spread AS t_ac_int_spread,
    a.t_date_int_acc_to AS t_date_int_acc_to,
    a.t_actual_acc_amt AS t_actual_acc_amt,
    a.t_currency AS t_currency,
    a.t_outs_susp_int AS t_outs_susp_int,
    a.t_outs_accrued_comm AS t_outs_accrued_comm,
    a.t_last_int_rev_date AS t_last_int_rev_date,
    a.t_next_int_rev_date AS t_next_int_rev_date,
    a.t_prev_int_st_date AS t_prev_int_st_date,
    a.t_int_accr_start AS t_int_accr_start,
    a.t_committed_comm AS t_committed_comm
FROM {{ ref('v_stg_t24_t24_lmm_account_balances') }} a
WHERE a.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND a.id like 'MM%'
{%- endset %}

-- Su dung satellite macro voi cau lenh raw_sql tuy chinh
{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

