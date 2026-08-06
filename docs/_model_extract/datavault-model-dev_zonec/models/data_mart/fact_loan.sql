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



with bridge_loan_adjust as (
    select
        *,
        bl.crb_tieukhoan as account_no,
        bl.loans_business_key as loan_no,
        bl.loans_payment_due_business_key as ovd_loan_no
    from {{ ref('bridge_loan') }}  bl
    where bl.snapshot_date = to_date('{{ tgt }}', 'yyyyMMdd')
),

tbl_crb_loan as (
    select
        bl.snapshot_date as data_date,
        case
            when ovd_loan_no like 'PDLD%' then substr(ovd_loan_no, 3)
            when account_no like 'PDLD%' then substr(account_no, 3)
            else account_no
        end as account_no,
        cast(bl.customer_business_key as string) as customer_id,
        scb.NGOAITE as currency,
        bl.crb_gl as gl_code,
        scb.category,
        sum(case when scb.NGOAITE = 'VND' then scb.NOITE else scb.NGOAITE1 end) as outstanding_bal,
        sum(scb.NOITE) as outstanding_bal_lcy
    from bridge_loan_adjust bl
    left join {{ ref('sat_crb_balance') }} scb
        on bl.crb_hashkey = scb.crb_hashkey
       and scb.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')
    where (
        bl.crb_gl like '2%'
        and (bl.crb_gl not like ' 2%9%' or bl.crb_gl in ('2910', '2920', '2930'))
        and substr(bl.account_no, 1, 3) not in ('VND', 'ROU', 'TOT')
        and account_no is not null
    )
    group by 1, 2, 3, 4, 5, 6
),

tbl_loan as (
    select
        bl.snapshot_date as data_date,
        bl.loan_no as id,
        case
            when substr(scc.CUST_GROUP, 1, 1) in ('1', '5')
             and scc.SECTOR not like '2%'
            then 'Y' else 'N'
        end as rb_flag,
        case
            when bl.loan_no like 'VND%' then substr(bl.loan_no, 4, 5)
            when slc.t_category = '21068' and slc.T_ocb_prod_main = '00' then '21050'
            when slc.t_category = '21068' and slc.T_ocb_prod_main = '01' then '21051'
            when slc.t_category = '21068' and slc.T_ocb_prod_main = '02' then '21052'
            when slc.t_category = '21068' and slc.T_ocb_prod_main = '03' then '21053'
            when slc.t_category = '21068' and slc.T_ocb_prod_main = '04' then '21054'
            when slc.t_category = '21068' and slc.T_ocb_prod_main = '10' then '21060'
            when slc.t_category = '21068' and slc.T_ocb_prod_main = '12' then '21062'
            when slc.t_category = '21068' and slc.T_ocb_prod_main = '24' then '21074'
            else cast(slc.t_category as string)
        end as rb_category,
        case when slt.T_VALUE_DATE < '20240229' then 'Y' else 'N' end as value_date_before_20240229,
        case
            when (slc.T_OCB_PRO_BUNDLE = 20 and bl.dept_acct_officer_business_key = 2019)
              or slc.T_OCB_PRO_BUNDLE = 34
            then 'COCAU'
            else 'KHONG_COCAU'
        end as loan_restructured,
        bl.branch_business_key as co_code,
        sli.t_currency as currency,
        slt.t_VALUE_DATE as value_date,
        slt.t_FIN_MAT_DATE as fin_mat_date,
        sli.t_DRAWDOWN_NET_AMT as drawdown_net_amt,
        slt.t_TERM as term,
        slr.t_INTEREST_RATE as interest_rate,
        sli.t_VMB_LN_CLASS as vmb_ln_class,
        slc.t_ocb_prod_main as ocb_prod_main,
        slc.T_LOAN_SUBPRODUCT as loan_subproduct,
        slc.T_OCB_PRO_PARTNER as ocb_production_partner,
        slc.T_LOAN_PURPOSE as loan_purpose,
        slc.T_INDUSTRY_LEVT as industry_levt,
        slc.T_INDUSTRY_LEV1 as industry_lev1,
        slc.t_category as category,
        slc.T_OCB_PROMOTION as ocb_promotion,
        slc.T_OCB_PRO_BUNDLE as ocb_pro_bundle,
        bl.dept_acct_officer_business_key as mis_acct_officer,
        coalesce(scc.ASSET_CLASS, 1) as asset_class,
        bl.saleid_business_key as sales_id,
        case
            when sli.t_currency = 'VND' then 1
            when instr(rcu.T_MID_REVAL_RATE, '::') > 0
                then try_cast(substring(rcu.T_MID_REVAL_RATE, 1, instr(rcu.T_MID_REVAL_RATE, '::') - 1) as float)
            else try_cast(rcu.T_MID_REVAL_RATE as float)
        end as exch_rate
    from bridge_loan_adjust bl
    left join {{ ref('pit_loan') }} pl
        on bl.loans_hashkey = pl.loans_hashkey
       and bl.snapshot_date = pl.snapshot_date
       and pl.snapshot_date = to_date('{{ tgt }}', 'yyyyMMdd')
    left join {{ ref('pit_customer') }} pc
        on bl.customer_hashkey = pc.customer_hashkey
       and bl.snapshot_date = pc.snapshot_date
       and pc.snapshot_date = to_date('{{ tgt }}', 'yyyyMMdd')
    left join {{ ref('sat_loans_rate') }} slr
        on bl.loans_hashkey = slr.loans_hashkey
       and pl.sat_loans_rate_src_ev_dt = slr.source_event_date
    left join {{ ref('sat_loans_information') }} sli
        on bl.loans_hashkey = sli.loans_hashkey
       and pl.sat_loans_information_src_ev_dt = sli.source_event_date
    left join {{ ref('sat_loans_classification') }} slc
        on bl.loans_hashkey = slc.loans_hashkey
       and pl.sat_loans_classification_src_ev_dt = slc.source_event_date
    left join {{ ref('sat_loans_terms') }} slt
        on bl.loans_hashkey = slt.loans_hashkey
       and pl.sat_loans_terms_src_ev_dt = slt.source_event_date
    left join {{ ref('sat_customer_classification') }} scc
        on bl.customer_hashkey = scc.customer_hashkey
       and pc.sat_customer_classification_src_ev_dt = scc.source_event_date
    left join {{ ref('ref_currency') }} rcu
        on sli.t_currency = rcu.id
       and date_format(bl.snapshot_date, 'yyyyMMdd') = rcu.data_date
    where bl.snapshot_date = to_date('{{ tgt }}', 'yyyyMMdd')
),

t1 as (
    select
        try_to_date(cast(c.data_date as string), 'yyyy-MM-dd') as date_cob,
        c.ACCOUNT_NO as ACCOUNT_NO,
        c.customer_id as customer_id,
        ld.co_code as branch_code,
        c.gl_code as gl_code,
        c.currency as currency,
        try_to_date(ld.value_date, 'yyyyMMdd') as value_date,
        try_to_date(ld.fin_mat_date, 'yyyyMMdd') as maturity_date,
        ld.drawdown_net_amt as draw_down_amt,
        cast(
            case
                when c.currency = 'VND' then ld.drawdown_net_amt
                else ld.drawdown_net_amt * ld.exch_rate
            end as decimal(25, 4)
        ) as draw_down_amt_lcy,
        cast(0 - c.outstanding_bal as decimal(25, 4)) as outstanding_bal,
        cast(0 - c.outstanding_bal_lcy as decimal(25, 4)) as outstanding_bal_lcy,
        ld.term as term,
        ld.interest_rate as interest_rate,
        ld.vmb_ln_class as ln_class,
        ld.ocb_prod_main as t_ocb_prod_main,
        ld.loan_subproduct as loan_subproduct,
        ld.ocb_production_partner as product_partner,
        ld.loan_purpose as loan_purpose,
        ld.industry_levt as industry_code,
        ld.industry_lev1 as industry_code_l1,
        ld.category as category,
        cast(ld.rb_category as decimal(6, 0)) as rb_category,
        case
            when rb_flag = 'Y'
             and (
                  (rb_category = '21050' and loan_subproduct in ('109','110','111','116', '148', '149', '150', '151'))
                  or ocb_production_partner in ('NH0080', 'NH0082')
             )
            then 'NHA_DU_AN'

            when rb_flag = 'Y'
             and (
                  (rb_category = '21050' and loan_subproduct in ('108') and value_date_before_20240229 = 'Y')
                  or rb_category in ('21054','21074')
             )
            then 'SXKD'

            when rb_flag = 'Y'
             and (
                  (rb_category = '21050' and loan_subproduct in ('108') and value_date_before_20240229 = 'N')
                  or (rb_category = '21050' and loan_subproduct not in ('109','110','111','116', '118','119', '148', '149', '150', '151'))
             )
            then 'NHA_RIENG_LE_KHAC'

            when rb_flag = 'Y'
             and (rb_category = '21050' and loan_subproduct in ('118','119'))
            then 'NHA_RIENG_LE_DREAMHOME'

            when rb_flag = 'Y' and rb_category = '21051'
            then 'XE'

            when rb_flag = 'Y'
             and (
                  rb_category in ('21052','21060')
                  and loan_subproduct not in ('306','309','312','313', '314', '901','902')
             )
            then 'VAY_TIEU_DUNG_TSBD'

            when rb_flag = 'Y'
             and (
                  rb_category in ('21052','21060')
                  and loan_subproduct in ('306','309','312','313', '314', '901','902')
             )
            then 'VAY_TIEU_DUNG_TIN_CHAP'

            when rb_flag = 'Y' and rb_category = '21055'
            then 'DAU_TU'
            else 'OTHER'
        end as rb_product,
        ld.rb_flag as rb_flag,
        cast(null as string) as related_account_no,
        cast(null as string) as collateral_code,
        cast(null as string) as limit_ref,
        ld.loan_restructured as loan_restructured,
        ld.ocb_promotion as promotion_id,
        ld.ocb_pro_bundle as promotion_bundle,
        ld.mis_acct_officer as mis_acct_officer,
        cast(ld.asset_class as decimal(4)) as asset_class,
        case
            when c.category in ('1008','1023','1039','1050') then 'OD'
            when c.account_no like 'PDPD%' then 'OD_OVD'
            else 'LOAN'
        end as src,
        ld.sales_id as sales_id
    from tbl_crb_loan c
    left join tbl_loan ld
        on c.account_no = ld.id
        and c.data_date = ld.data_date
)

select *
from t1
