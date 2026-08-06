{% set tgt = var('target_date') %}

{{
  config(
    materialized='incremental',
    incremental_strategy='append',
    pre_hook=[
      "delete from {{ this }} where data_date = to_date('" ~ tgt ~ "', 'yyyyMMdd')"
    ],
    skip_matched_step = true,
    auto_liquid_cluster = true,
    catalog = var('curated_catalog'),
    tags=['t24']
  )
}}

with pit_acnt_contract_cte as (
  SELECT
    acnt_contract_hashkey,
    snapshot_date,
    sat_acnt_contract_information_src_ev_dt,
    sat_acnt_contract_type_src_ev_dt,
    sat_acnt_contract_add_data_src_ev_dt
  FROM {{ ref('pit_acnt_contract') }}
  WHERE snapshot_date = to_date('{{ tgt }}', 'yyyyMMdd')
),
ref_status AS (
SELECT
  LEFT(ref_code, LENGTH(ref_code) - 2) AS contr_status_key,
  Ref_description
FROM  {{ ref('ref_way4_contr_status') }}
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY LEFT(ref_code, LENGTH(ref_code) - 2)
  ORDER BY source_event_date DESC
) = 1
),
t1 AS (
  SELECT 
bc.snapshot_date data_date,
sci.contract_number as card_number,
saci.contract_number account_number,
bc.customer_business_key as customer_id,
ref_cs.Ref_description as card_status,
ref_cs_a.Ref_description as account_status,
bc.branch_business_key as branch_code,
sci.date_open as open_date_new,
'null' as open_date_old,
substr(spi.code, 2, 1) card_class,
substr(spi.code, 5, 1) main_sub,
spi.code || '-' || spi.name as product_name,
'null' as card_rank,
regexp_extract(sct.ext_data, 'LAST_PRODUCTION_TYPE=([^;]+)', 1) card_type,
case when substr(spi.code, 2, 1) = 'D' then 0 else coalesce(-saci.total_balance, 0) end current_balance,
case when substr(spi.code, 2, 1) = 'D' then 0 else -saci.auth_limit_amount end issuing_credit_limit,
'null' as pre_apprv_card_flag,
'null' as pre_apprv_add_status,
'null' as card_classifier_name,
'null' as credit_policy_name,
'null' as credit_policy_code,
'null' as activation_date,
regexp_extract(sct.ext_data, 'LAST_TRANS_DATE=([^;]+)', 1) TRAN_DATE_MAX,
regexp_extract(sct.ext_data, 'FIRST_TRANS_DATE=([^;]+)', 1) TRAN_DATE_MIN,
regexp_extract(sct.ext_data, 'SALE_CODE=([^;]+)', 1) SALE_CODE,
regexp_extract(sct.ext_data, 'SALE_NAME=([^;]+)', 1) SALE_NAME,
case 
  when datediff(
    least(
      last_day(COALESCE(try_to_date(sci.date_expire, 'yyyy-MM-dd'), try_to_date(sci.date_expire, 'M/d/yyyy'))),
      COALESCE(try_to_date(sci.date_expire, 'yyyy-MM-dd'), try_to_date(sci.date_expire, 'M/d/yyyy'))
    ),
    current_date()) <= 0
  then 'THE_HET_HAN'
  else 'CON_HAN'
end as expiry_status,
sci.date_expire as date_expire,
'null' as change_date_max,
'null' as reason_change_card_status,
'null' as writeoff_flag
from {{ ref('bridge_card') }} bc
join pit_acnt_contract_cte pc on bc.card_hashkey = pc.acnt_contract_hashkey and bc.snapshot_date = pc.snapshot_date
join pit_acnt_contract_cte pac on bc.account_contract_hashkey = pac.acnt_contract_hashkey and bc.snapshot_date = pac.snapshot_date
join {{ ref('sat_acnt_contract_information')}} sci
    ON  pc.acnt_contract_hashkey                           = sci.acnt_contract_hashkey
    AND pc.sat_acnt_contract_information_src_ev_dt = sci.source_event_date
join {{ ref('sat_acnt_contract_information')}} saci
    ON  pac.acnt_contract_hashkey                 = saci.acnt_contract_hashkey
    AND pac.sat_acnt_contract_information_src_ev_dt = saci.source_event_date
join {{ ref('sat_product_information') }} spi on bc.product_hashkey = spi.product_hashkey 
join {{ ref('sat_acnt_contract_type') }} sct
    ON  pc.acnt_contract_hashkey                     = sct.acnt_contract_hashkey
    AND pc.sat_acnt_contract_type_src_ev_dt = sct.source_event_date
LEFT JOIN ref_status ref_cs   ON sci.contr_status  = ref_cs.contr_status_key
LEFT JOIN ref_status ref_cs_a ON saci.contr_status = ref_cs_a.contr_status_key
where bc.snapshot_date = to_date('{{ tgt }}', 'yyyyMMdd')
and bc.customer_business_key is not null
)
select * from t1
