{% set tgt = var('target_date') %}

{{
  config(
    materialized='incremental',
    incremental_strategy='append',
    pre_hook=[
      "delete from {{ this }} where date_cob = to_date('" ~ tgt ~ "', 'yyyyMMdd')"
    ],
    skip_matched_step = true,
    auto_liquid_cluster = true,
    catalog = var('curated_catalog'),
    tags=['t24']
  )
}}

select data_date as date_cob,
       customer_id,
       current_balance_lcy balance_lcy_amt,
       account_no,
       gl_code,
       currency,
       branch_code,
       category,
       open_date,
       close_date,
       value_date,
       maturity_date,
       term,
       term_days,
       ocb_beauty,
       product_group,
       'null' as interest_rate
from  {{ ref('twt_cx_deposit') }} c
where product_group = 'FD'
and data_date = to_date('{{ tgt }}', 'yyyyMMdd')