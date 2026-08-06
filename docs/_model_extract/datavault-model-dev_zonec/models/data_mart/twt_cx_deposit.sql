{% set tgt = var('target_date') %}
{% set ym = tgt[:6] %}

{{ config(
  materialized = 'incremental',
  incremental_strategy='append',
    pre_hook=[
      "delete from {{ this }} where data_date = to_date('" ~ tgt ~ "', 'yyyyMMdd')"
    ],
  skip_matched_step = true,
  auto_liquid_cluster = true,
  catalog = var('curated_catalog'),
  tags = ['t24']
)}}

with account_info as (
    select
        ba.snapshot_date as data_date,
        ba.account_hashkey,
        ba.crb_hashkey,
        ba.account_business_key as account_no,
        ba.customer_business_key as customer_id,
        ba.branch_business_key as branch_code,
        sac.t_category as category,
        sai.t_opening_date as open_date,
        case
            when coalesce(sdi.t_maturity_date, sai.t_mature_date) is not null
                then coalesce(sdi.t_value_date, sai.t_create_date, sai.t_opening_date)
            else null
        end as value_date,
        coalesce(sdi.t_maturity_date, sai.t_mature_date) as maturity_date,
        coalesce(sdt.t_term, sai.t_term_xau) as term,
        sai.t_ocb_beauty_sts as ocb_beauty,
        sai.t_posting_restrict as blocked_account
    from {{ ref('bridge_account') }} ba
    join {{ ref('pit_account') }} pa on ba.account_hashkey = pa.account_hashkey and ba.snapshot_date = pa.snapshot_date
    left join {{ ref('sat_account_information') }} sai
      on pa.account_hashkey = sai.account_hashkey and pa.sat_account_information_src_ev_dt = sai.source_event_date
    left join {{ ref('sat_account_classification') }} sac 
      on pa.account_hashkey = sac.account_hashkey and pa.sat_account_classification_src_ev_dt = sac.source_event_date
    left join {{ ref('sat_deposits_information') }} sdi
      on pa.account_hashkey = sdi.deposit_hashkey and pa.sat_deposits_information_src_ev_dt = sdi.source_event_date
    left join {{ ref('sat_deposits_terms') }} sdt
      on pa.account_hashkey = sdt.deposit_hashkey and pa.sat_deposits_terms_src_ev_dt = sdt.source_event_date
where ba.snapshot_date = to_date('{{ tgt }}', 'yyyyMMdd') and ba.account_hashkey is not null
union all 
select
    bl.snapshot_date as data_date,
    bl.loans_hashkey     as account_hashkey,
    bl.crb_hashkey as crb_hashkey,
    bl.loans_business_key      as account_no,
    bl.customer_business_key      as customer_id,
    bl.branch_business_key      as branch_code,
    slc.t_category as category,
    slt.t_value_date        as open_date,
    slt.t_value_date        as value_date,
    slt.t_fin_mat_date      as maturity_date,
    slt.t_term,
    null                as ocb_beauty,
    null                as blocked_account
from {{ ref('bridge_account') }} as bl
left join {{ ref('pit_loan') }} as pl on bl.loans_hashkey = pl.loans_hashkey and bl.snapshot_date = pl.snapshot_date
-- join sat lay thong tin
left join {{ ref('sat_loans_classification') }} as slc on pl.loans_hashkey = slc.loans_hashkey and  pl.sat_loans_classification_src_ev_dt = slc.source_event_date
left join {{ ref('sat_loans_terms') }} as slt on pl.loans_hashkey = slt.loans_hashkey and  pl.sat_loans_terms_src_ev_dt = slt.source_event_date
where bl.snapshot_date = to_date('{{ tgt }}', 'yyyyMMdd') and bl.loans_hashkey is not null
)
,
get_info_from_crb as (

    select
        to_date('{{ tgt }}', 'yyyyMMdd') as data_date,
        hc.tieukhoan as account_no,
        a.customer_id as customer_id_a,
        a.branch_code,
        a.category,
        to_date(a.open_date, 'yyyyMMdd') as open_date,
        cast(null as date) as close_date,
        to_date(a.value_date, 'yyyyMMdd') as value_date,
        to_date(a.maturity_date, 'yyyyMMdd') as maturity_date,
        a.term,
        date_diff(
            day,
            to_date(a.value_date, 'yyyyMMdd'),
            to_date(a.maturity_date, 'yyyyMMdd')
        ) as term_days,
        hc.gl as gl_code,
        a.ocb_beauty,
        sum(scb.noite) as current_balance_lcy

    from {{ ref('hub_crb') }} hc 
    left join account_info a
      on a.crb_hashkey = hc.crb_hashkey
    join {{ ref('sat_crb_balance') }} scb
      on hc.crb_hashkey = scb.crb_hashkey and scb.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')
     where substring(hc.gl, 1, 2) in ('41','42','43','44')

    group by
        hc.tieukhoan,
        a.customer_id,
        a.branch_code,
        a.category,
        to_date(a.open_date, 'yyyyMMdd'),
        cast(null as date),
        to_date(a.value_date, 'yyyyMMdd'),
        to_date(a.maturity_date, 'yyyyMMdd'),
        a.term,
        date_diff(
            day,
            to_date(a.value_date, 'yyyyMMdd'),
            to_date(a.maturity_date, 'yyyyMMdd')
        ),
        hc.gl,
        a.ocb_beauty

)
,
src as (
select to_date('{{ tgt }}', 'yyyyMMdd') as data_date,
       a.account_no,
       case when a.customer_id is not null then a.customer_id else b.customer_id_a end as customer_id,
       a.gl gl_code,
       a.currency,
       b.branch_code,
       b.category,
       b.open_date,
       b.close_date,
       b.value_date,
       b.maturity_date,
       b.term,
       b.term_days,
       b.ocb_beauty,
       b.current_balance_lcy,
       a.agg_balance_lcy mtd_agg_balance,
       case when a.gl in ('4212','4222','4232','4242','4252','4262','4310')
            or (a.gl in ('4224','4214') and maturity_date is not null)
            or (substring(a.gl, 1, 3) = '427' and maturity_date is not null)
            or (substring(a.gl, 1, 3) = '428' and maturity_date is not null)
            or substring(a.gl , 1, 2) = '41'
            or substring (a.gl , 1, 2) = '44'
            then 'FD' else 'CASA' end AS product_group

from {{ ref('twt_cx_deposit_agg_m') }} a
left join get_info_from_crb b
  on a.account_no = b.account_no 
where a.ym = '{{ ym }}'
)
select * from src
