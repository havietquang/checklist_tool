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

select 
  date(to_date(bd.snapshot_date, 'yyyyMMdd')) as date_cob,
  case 
    when cast(bd.document_business_key as string) = 'RBS_BANK_ACCOUNT' then sdwt_auth.target_number 
    else sdwt_fin.target_number 
  end as card_number,
  cast(bd.customer_business_key as string) as customer_id,
  sdwc.trans_type,
  case 
    when sdwc.trans_condition like '%ENET%' then 'ECOMMERCE'
    when sdwc.trans_condition like '%ATM%' then 'ATM'
    when sdwc.trans_condition like '%POS%' then 'POS'
    when sdwc.trans_condition like '%CAT%' then 'CAT'
    else 'OTHER' 
  end as card_trans_type,

  case 
    when sdws.source_channel in ('A','P') then 'OnUs' 
    when coalesce(sdwd.trans_country, 'VNM') = 'VNM' then 'OffUs-Domestic'
    when coalesce(sdwd.trans_country, 'VNM') != 'VNM' then 'OffUs-International'
  end as on_us_off_us,

  sdwd.trans_amount as local_amount,
  coalesce(sdwd.trans_country, 'VNM') as trans_place,
  sdwd.trans_date as doc_tran_date,
  sdwd.posting_date as posting_date,
  rws.ref_description as mcc,
  sdwd.sic_code as mcc_code,
  sdwd.merchant_id as merchant_id,
  sdwd.trans_details as merchant_name,
  bd.document_business_key as doc_id

from {{ ref('bridge_doc') }} bd
left join {{ ref('sat_document_target') }} sdwt_fin 
  on bd.document_fin_hashkey = sdwt_fin.document_hashkey
  and sdwt_fin.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')
left join {{ ref('sat_document_target') }} sdwt_auth
  on bd.document_auth_hashkey = sdwt_auth.document_hashkey
  and sdwt_auth.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')
left join {{ ref('sat_document_source') }} sdws
  on bd.document_fin_hashkey = sdws.document_hashkey
  and sdws.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')
left join {{ ref('sat_document_classification') }} sdwc
  on bd.document_fin_hashkey = sdwc.document_hashkey
  and sdwc.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')
left join {{ ref('sat_document_description') }} sdwd
  on bd.document_fin_hashkey = sdwd.document_hashkey
  and sdwd.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')
left join {{ ref('ref_way4_sic') }} rws
  on right(rws.ref_code, 4) = sdwd.sic_code
where bd.snapshot_date = to_date('{{ tgt }}', 'yyyyMMdd')

