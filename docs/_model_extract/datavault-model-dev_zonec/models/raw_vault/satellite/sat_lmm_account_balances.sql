/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record mới/thay đổi
                    : 'table' = full load
                    : 'view' = chỉ tạo view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chỉ insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khóa định danh record (thường: hub_hashkey + hashdiff)
skip_matched_step   : true = bỏ record không đổi → tăng performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/

{{ config(
    alias = 'sat_lmm_account_balances',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['loans_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'loan', 'phase1', 'all']
) }}

/*
========================================================================
SATELLITE MACRO PARAMETERS
========================================================================
  - source_name         : Tên hệ thống nguồn, dùng để tạo giá trị cho cột `record_source`.
  - source_table        : Tên bảng nghiệp vụ ở hệ thống nguồn.
  - hashdiff_col        : Tên cột hashdiff đã được tính sẵn ở tầng staging.
  - hub_hashkey         : Tên khóa hash dùng để liên kết về bảng Hub.
  - source_model        : Model staging làm nguồn để đọc dữ liệu.
  - list_cols           : Danh sách các cột nghiệp vụ được lưu trong Satellite.
  - raw_sql (optional)  : Câu SQL tự viết trong trường hợp logic phức tạp hoặc đặc biệt.
*/

{% set source_name = 't24' %}
{% set source_table = 't24_lmm_account_balances' %}
{% set cols_name = ['a.t_date_from', 'a.t_effective_date', 'a.t_trans_prin_amt', 'a.t_outs_curr_princ', 'a.t_outs_accrued_int', 'a.t_start_period_int', 'a.t_end_period_int', 'a.t_committed_int', 'a.t_princ_int_bal', 'a.t_int_amt_todate', 'a.t_ac_int_rate', 'a.t_ac_int_spread', 'a.t_date_int_acc_to', 'a.t_actual_acc_amt', 'a.t_currency', 'a.t_outs_susp_int'] %}
{% set hashdiff_col = hash_column(cols_name, source_name) %}
{% set hub_hashkey = 'loans_hashkey' %}
{% set source_model = 'v_stg_t24_t24_lmm_account_balances' %}
{% set raw_sql -%}
SELECT
    a.hashkey AS loans_hashkey,
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
    a.t_outs_susp_int AS t_outs_susp_int
FROM {{ ref(source_model) }} a
WHERE a.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND a.id LIKE 'LD%'
{%- endset %}

-- Su dung satellite macro voi cau lenh raw_sql tuy chinh
{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

