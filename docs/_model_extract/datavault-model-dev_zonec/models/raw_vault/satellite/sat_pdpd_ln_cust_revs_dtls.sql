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
    alias = 'sat_pdpd_ln_cust_revs_dtls',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['loans_payment_due_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'loan', 'phase1', 'all']
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
{% set source_table = 't24_ln_cust_revs_dtls' %}
{% set cols_name = ['a.t_date', 'a.account_balance', 'a.total_accrual', 'a.contract_id', 'a.outs_amount', 'a.currency', 'a.k_type', 'a.outs_accr_int', 'a.stmt_no', 'a.t_line_no', 'a.t_account_no', 'a.t_pre_line_no', 'a.t_pre_account_no'] %}
{% set hashdiff_col = hash_column(cols_name, source_name) %}
{% set hub_hashkey = 'loans_payment_due_hashkey' %}
{% set source_model = 'v_stg_t24_t24_ln_cust_revs_dtls' %}
{% set raw_sql -%}
SELECT
    a.hashkey AS loans_payment_due_hashkey,
    {{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(cast('{{source_name}}' as string), '__', '{{source_table}}') AS record_source,
    a.t_date AS t_date,
    a.account_balance AS account_balance,
    a.total_accrual AS total_accrual,
    a.contract_id AS contract_id,
    a.outs_amount AS outs_amount,
    a.currency AS currency,
    a.k_type AS k_type,
    a.outs_accr_int AS outs_accr_int,
    a.stmt_no AS stmt_no,
    a.t_line_no AS t_line_no,
    a.t_account_no AS t_account_no,
    a.t_pre_line_no AS t_pre_line_no,
    a.t_pre_account_no AS t_pre_account_no
FROM {{ ref(source_model) }} a
WHERE a.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND a.id LIKE 'PDPD%'
{%- endset %}

-- Su dung satellite macro voi cau lenh raw_sql tuy chinh
{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

