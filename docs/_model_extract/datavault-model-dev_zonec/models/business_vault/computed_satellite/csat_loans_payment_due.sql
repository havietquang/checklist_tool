/*
================================================================================
DBT CONFIGURATION GUIDE
================================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record cua Computed Satellite
skip_matched_step   : true = bo qua record khong doi de tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<ten_nguon>'] = filter khi run (dbt run --select tag:<ten_nguon>)
================================================================================
*/
{{ config(
    alias = 'csat_loans_payment_due',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    skip_matched_step = true,
    unique_key = ['loans_payment_due_hashkey', 'hashdiff', 'source_event_date'],
    tags = ['t24', 'loan', 'zonec', 'bv_zonec']
) }}

/*
========================================================================
COMPUTED SATELLITE: csat_loans_payment_due
========================================================================
IMPORT CHUNG (dung cho ca 3 luong):
  - deleted_entities: loai hashkey co cdc_status moi nhat = 'D'.
  - fx_rate: ty gia quy doi ve VND (VND=1, ngoai te lay t_reval_rate, fallback t_mid_reval_rate).

3 luong nguon:

  A. T24_LD_SCHEDULE_DEFINE   -> business_key LIKE 'PDLD%'
                                  Nguon: csat_loans_schedule (qua
                                  link_loans_payment_due -> hub).
                                  TOT_PD_PR = SUM t_amount(P), TOT_PD_INT =
                                  SUM t_amount(I), quy doi VND.
                                  MAX_PD_PR/IN_DAYS = DATEDIFF tu MIN(t_k_date)
                                  theo t_sch_type. PE/PS = 0/NULL.

  B. T24_PAYMENT_DUE (PDLD)   -> business_key LIKE 'PDLD%'
                                  Loc tu shared_paymentdue_join (hub + info +
                                  overdue + contract) - dung chung voi Luong C.
                                  Explode 2 cap: '::' (ky han, sch_pos >= 10)
                                  roi '!!' (cau phan tien te). Tinh du
                                  TOT_PD_PR/INT/PE/PS theo t_pay_type_comp
                                  (PR/IN/PE/PS), t_pay_amt_outs quy doi VND;
                                  MAX_*_DAYS = DATEDIFF tu MIN(t_pay_dte_due).

  C. T24_PAYMENT_DUE (PDPD)   -> business_key LIKE 'PDPD%'
                                  Loc tu shared_paymentdue_join (cung join goc
                                  voi Luong B), chi khac filter PDPD%.
                                  Chi tinh TOT_PD_PR: explode t_orig_limit_ref
                                  ('!!') -> hub_account -> sat_account_balance
                                  (t_open_actual_bal quy doi VND).
                                  INT/PE/PS = 0, MAX_*_DAYS = NULL.

KET QUA: UNION ALL 3 luong roi GROUP BY hashkey (SUM tot_*, MAX max_*_days).
========================================================================
*/

{% set hashkey_col = 'loans_payment_due_hashkey' %}
{% set target_date_sql = "to_date('" ~ var("target_date") ~ "', 'yyyyMMdd')" %}

{% set computed_cols = [
    {'alias': 'tot_pd_pr'},
    {'alias': 'tot_pd_int'},
    {'alias': 'tot_pd_pe'},
    {'alias': 'tot_pd_ps'},
    {'alias': 'max_pd_pr_days'},
    {'alias': 'max_pd_in_days'},
    {'alias': 'max_pd_pe_days'},
    {'alias': 'max_pd_ps_days'}
] %}

{% set raw_sql %}
/* ============================================================
   IMPORT BANG CHUNG - dung xuyen suot ca 3 luong A/B/C
   ============================================================ */
-- Lay cac hashkey da bi xoa tai target_date (cdc_status moi nhat = 'D')
WITH deleted_entities AS (
    SELECT loans_payment_due_hashkey
    FROM (
        SELECT
            loans_payment_due_hashkey,
            cdc_status,
            ROW_NUMBER() OVER (PARTITION BY loans_payment_due_hashkey ORDER BY source_event_date DESC) AS rn
        FROM {{ source('raw_vault','sts_hub_loans_payment_due') }}
        WHERE source_event_date <= {{ target_date_sql }}
    )
    WHERE rn = 1 AND cdc_status = 'D'
),

-- Ty gia quy doi ve VND theo tung currency (VND = 1, ngoai te = t_reval_rate, fallback t_mid_reval_rate)
fx_rate AS (
    SELECT
        id AS currency_id,
        CASE
            WHEN upper(id) = 'VND' THEN CAST(1 AS decimal(17,6))
            ELSE COALESCE(
                NULLIF(CAST(t_reval_rate AS decimal(17,6)), CAST(0 AS decimal(17,6))),
                CAST(t_mid_reval_rate AS decimal(17,6)),
                CAST(0 AS decimal(17,6))
            )
        END AS rate
    FROM {{ source('raw_vault','ref_currency') }}
    WHERE t_currency_market = '1'
      AND source_event_date = {{ target_date_sql }}
),

/* ============================================================
   LUONG A - T24_LD_SCHEDULE_DEFINE (business_key LIKE 'PDLD%')
   ============================================================ */
-- link_loans_payment_due khong co effsat -> group by loans_payment_due_hashkey, lay ban ghi co max source_event_date 
latest_link_loans_payment_due AS (
    SELECT loans_payment_due_hashkey, loans_hashkey
    FROM {{ source('raw_vault','link_loans_payment_due') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY loans_payment_due_hashkey
        ORDER BY source_event_date DESC
    ) = 1
),

-- lay gia trị moi nhat cua hashkey trong bang satellite
latest_schedule AS (
    SELECT *
    FROM {{ ref('csat_loans_schedule') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY loans_hashkey, t_k_date, t_sch_type, t_cycled_dates, k_date_seq, cycled_dates_seq
        ORDER BY source_event_date DESC
    ) = 1
),

-- join cac bang, lay base
schedule_base AS (
    SELECT
        hub.loans_payment_due_hashkey,
        s.t_sch_type,
        to_date(s.t_k_date, 'yyyyMMdd')                                     AS t_k_date,
        cast(s.t_amount AS decimal(19,4)) * fx.rate                          AS amt_vnd
    FROM {{ source('raw_vault','hub_loans_payment_due') }} hub
    JOIN latest_link_loans_payment_due lnk
        ON lnk.loans_payment_due_hashkey = hub.loans_payment_due_hashkey
    JOIN latest_schedule s
        ON s.loans_hashkey = lnk.loans_hashkey
    LEFT JOIN fx_rate fx
        ON fx.currency_id = s.t_currency
    WHERE hub.business_key LIKE 'PDLD%'
      AND to_date(s.t_k_date, 'yyyyMMdd') <= {{ target_date_sql }}
      AND NOT EXISTS (
          SELECT 1 FROM deleted_entities del
          WHERE del.loans_payment_due_hashkey = hub.loans_payment_due_hashkey
      )
),

-- tinh toan ket qua
schedule_agg AS (
    SELECT
        loans_payment_due_hashkey,
        SUM(CASE WHEN t_sch_type = 'P' THEN amt_vnd ELSE CAST(0 AS decimal(38,10)) END)             AS tot_pd_pr,
        SUM(CASE WHEN t_sch_type = 'I' THEN amt_vnd ELSE CAST(0 AS decimal(38,10)) END)             AS tot_pd_int,
        CAST(0 AS decimal(38,10))                                            AS tot_pd_pe,
        CAST(0 AS decimal(38,10))                                            AS tot_pd_ps,
        DATEDIFF(
            {{ target_date_sql }},
            MIN(CASE WHEN t_sch_type = 'P' THEN t_k_date
                     ELSE {{ target_date_sql }} END)
        )                                                                     AS max_pd_pr_days,
        DATEDIFF(
            {{ target_date_sql }},
            MIN(CASE WHEN t_sch_type = 'I' THEN t_k_date
                     ELSE {{ target_date_sql }} END)
        )                                                                     AS max_pd_in_days,
        CAST(NULL AS int)                                                     AS max_pd_pe_days,
        CAST(NULL AS int)                                                     AS max_pd_ps_days
    FROM schedule_base
    GROUP BY loans_payment_due_hashkey
),

/* ============================================================
   JOIN CHUNG cho Luong B (PDLD) va Luong C (PDPD): hub + info +
   overdue + contract, loai bo cac hashkey da xoa. Luong B & C 
   su dung chung logic nay truoc khi xu ly logic rieng.
   ============================================================ */
-- lay gia trị moi nhat cua hashkey trong bang satellite information
latest_info AS (
    SELECT *
    FROM {{ source('raw_vault','sat_loans_payment_due_information') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY loans_payment_due_hashkey
        ORDER BY source_event_date DESC
    ) = 1
),

-- lay gia trị moi nhat cua hashkey trong bang satellite overdue
latest_ovd AS (
    SELECT *
    FROM {{ source('raw_vault','sat_loans_payment_due_overdue') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY loans_payment_due_hashkey
        ORDER BY source_event_date DESC
    ) = 1
),

-- lay gia trị moi nhat cua hashkey trong bang satellite contract
latest_contract AS (
    SELECT *
    FROM {{ source('raw_vault','sat_loans_payment_due_contract') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY loans_payment_due_hashkey
        ORDER BY source_event_date DESC
    ) = 1
),

-- join cac bang sat lay thong tin can thiet
shared_paymentdue_join AS (
    SELECT
        hub.loans_payment_due_hashkey,
        hub.business_key,
        info.t_currency,
        info.t_payment_dte_due,
        info.t_payment_amount,
        ovd.t_pay_type,
        ovd.t_pay_amt_orig,
        ovd.t_pay_amt_outs,
        ovd.t_outstanding_amt,
        con.t_orig_limit_ref
    FROM {{ source('raw_vault','hub_loans_payment_due') }} hub
    JOIN latest_info info
        ON info.loans_payment_due_hashkey = hub.loans_payment_due_hashkey
    JOIN latest_ovd ovd
        ON ovd.loans_payment_due_hashkey = hub.loans_payment_due_hashkey
    JOIN latest_contract con
        ON con.loans_payment_due_hashkey = hub.loans_payment_due_hashkey
    WHERE NOT EXISTS (
          SELECT 1 FROM deleted_entities del
          WHERE del.loans_payment_due_hashkey = hub.loans_payment_due_hashkey
      )
),

/* ============================================================
   LUONG B - T24_PAYMENT_DUE (PDLD) (business_key LIKE 'PDLD%')
   Loc tu shared_paymentdue_join.
   ============================================================ */
pdld_base AS (
    SELECT
        loans_payment_due_hashkey,
        t_currency,
        t_payment_dte_due,
        t_payment_amount,
        t_pay_type,
        t_pay_amt_orig,
        t_pay_amt_outs,
        t_outstanding_amt
    FROM shared_paymentdue_join
    WHERE business_key LIKE 'PDLD%'
),

-- Buoc 2 - Explode cap 1 theo '::' -> _SCH (muc Ky han)
pdld_sch_exploded AS (
    SELECT
        b.loans_payment_due_hashkey,
        b.t_currency,
        t_pay_dte_due_sch,
        get(split(b.t_payment_amount, '::'), sch_pos) AS t_payment_amount_sch,
        get(split(b.t_pay_type,       '::'), sch_pos) AS t_pay_type_sch,
        get(split(b.t_pay_amt_orig,   '::'), sch_pos) AS t_pay_amt_orig_sch,
        get(split(b.t_pay_amt_outs,   '::'), sch_pos) AS t_pay_amt_outs_sch,
        get(split(b.t_outstanding_amt,'::'), sch_pos) AS t_outstanding_amt_sch
    FROM pdld_base b
    LATERAL VIEW posexplode(split(b.t_payment_dte_due, '::')) t AS sch_pos, t_pay_dte_due_sch
    WHERE sch_pos >= 10
),

-- Buoc 3 - Explode cap 2 theo '!!' -> _COMP (muc Cau phan tien te)
pdld_comp_exploded AS (
    SELECT
        s.loans_payment_due_hashkey,
        s.t_currency                                              AS t_currency_comp,
        s.t_pay_dte_due_sch                                       AS t_pay_dte_due_comp,
        s.t_payment_amount_sch                                    AS t_payment_amount_comp,
        s.t_outstanding_amt_sch                                   AS t_outstanding_amt_comp,
        t_pay_type_comp,
        get(split(s.t_pay_amt_orig_sch, '!!'), comp_pos)         AS t_pay_amt_orig_comp,
        get(split(s.t_pay_amt_outs_sch, '!!'), comp_pos)         AS t_pay_amt_outs_comp
    FROM pdld_sch_exploded s
    LATERAL VIEW posexplode(split(s.t_pay_type_sch, '!!')) c AS comp_pos, t_pay_type_comp
),

-- Quy doi t_pay_amt_outs_comp ve VND theo fx_rate
pdld_comp_converted AS (
    SELECT
        t.loans_payment_due_hashkey,
        t.t_pay_dte_due_comp,
        t.t_pay_type_comp,
        COALESCE(
            TRY_CAST(t.t_pay_amt_outs_comp AS decimal(19,4)) * fx.rate,
            CAST(0 AS decimal(19,4))
        ) AS amt_outs_vnd
    FROM pdld_comp_exploded t
    LEFT JOIN fx_rate fx
        ON fx.currency_id = t.t_currency_comp
),

-- tinh toan ket qua
paymentdue_pdld_agg AS (
    SELECT
        loans_payment_due_hashkey,
        COALESCE(SUM(CASE WHEN t_pay_type_comp = 'PR' THEN amt_outs_vnd END), CAST(0 AS decimal(38,10)))  AS tot_pd_pr,
        COALESCE(SUM(CASE WHEN t_pay_type_comp = 'IN' THEN amt_outs_vnd END), CAST(0 AS decimal(38,10)))  AS tot_pd_int,
        COALESCE(SUM(CASE WHEN t_pay_type_comp = 'PE' THEN amt_outs_vnd END), CAST(0 AS decimal(38,10)))  AS tot_pd_pe,
        COALESCE(SUM(CASE WHEN t_pay_type_comp = 'PS' THEN amt_outs_vnd END), CAST(0 AS decimal(38,10)))  AS tot_pd_ps,
        DATEDIFF(
            {{ target_date_sql }},
            MIN(CASE WHEN t_pay_type_comp = 'PR'
                     THEN to_date(t_pay_dte_due_comp, 'yyyyMMdd')
                     ELSE {{ target_date_sql }} END)
        )                                                                     AS max_pd_pr_days,
        DATEDIFF(
            {{ target_date_sql }},
            MIN(CASE WHEN t_pay_type_comp = 'IN'
                     THEN to_date(t_pay_dte_due_comp, 'yyyyMMdd')
                     ELSE {{ target_date_sql }} END)
        )                                                                     AS max_pd_in_days,
        DATEDIFF(
            {{ target_date_sql }},
            MIN(CASE WHEN t_pay_type_comp = 'PE'
                     THEN to_date(t_pay_dte_due_comp, 'yyyyMMdd')
                     ELSE {{ target_date_sql }} END)
        )                                                                     AS max_pd_pe_days,
        DATEDIFF(
            {{ target_date_sql }},
            MIN(CASE WHEN t_pay_type_comp = 'PS'
                     THEN to_date(t_pay_dte_due_comp, 'yyyyMMdd')
                     ELSE {{ target_date_sql }} END)
        )                                                                     AS max_pd_ps_days
    FROM pdld_comp_converted
    GROUP BY loans_payment_due_hashkey
),

/* ============================================================
   LUONG C - T24_PAYMENT_DUE (PDPD) (business_key LIKE 'PDPD%')
   Loc tu shared_paymentdue_join (cung join goc voi Luong B).
   TOT_PD_PR: rieng, qua contract -> explode t_orig_limit_ref ('!!')
   -> hub_account -> sat_account_balance.
   ============================================================ */
-- Explode t_orig_limit_ref theo !!
pdpd_limit_ref_exploded AS (
    SELECT
        loans_payment_due_hashkey,
        t_orig_limit_ref_comp
    FROM shared_paymentdue_join
    LATERAL VIEW explode(split(t_orig_limit_ref, '!!')) e AS t_orig_limit_ref_comp
    WHERE business_key LIKE 'PDPD%'
),

-- sat_account_balance la bang snapshot theo ngay (moi ngay 1 ban/key) -> lay dung source_event_date = target_date, khong can dedup lay ban moi nhat
latest_account_balance AS (
    SELECT *
    FROM {{ source('raw_vault','sat_account_balance') }}
    WHERE source_event_date = {{ target_date_sql }}
),

-- join bang sat lay thong tin can thiet
pdpd_balance_base AS (
    SELECT
        e.loans_payment_due_hashkey,
        cast(ab.t_open_actual_bal AS decimal(19,4)) * fx.rate      AS bal_vnd
    FROM pdpd_limit_ref_exploded e
    JOIN {{ source('raw_vault','hub_account') }} acc
        ON acc.business_key = e.t_orig_limit_ref_comp
    LEFT JOIN latest_account_balance ab
        ON ab.account_hashkey = acc.account_hashkey
    LEFT JOIN fx_rate fx
        ON fx.currency_id = ab.t_currency
),

-- tinh toan ket qua
paymentdue_pdpd_agg AS (
    SELECT
        loans_payment_due_hashkey,
        COALESCE(SUM(bal_vnd), CAST(0 AS decimal(38,10)))                   AS tot_pd_pr,
        CAST(0 AS decimal(38,10))                                            AS tot_pd_int,   -- N/A theo mapping
        CAST(0 AS decimal(38,10))                                            AS tot_pd_pe,    -- N/A theo mapping
        CAST(0 AS decimal(38,10))                                            AS tot_pd_ps,    -- N/A theo mapping
        CAST(NULL AS int)                                                     AS max_pd_pr_days, -- N/A theo mapping
        CAST(NULL AS int)                                                     AS max_pd_in_days,
        CAST(NULL AS int)                                                     AS max_pd_pe_days,
        CAST(NULL AS int)                                                     AS max_pd_ps_days
    FROM pdpd_balance_base
    GROUP BY loans_payment_due_hashkey
),

/* ============================================================
   UNION ALL 3 luong (A, B, C) + outer GROUP BY de gop
   ============================================================ */
all_sources AS (
    SELECT * FROM schedule_agg
    UNION ALL
    SELECT * FROM paymentdue_pdld_agg
    UNION ALL
    SELECT * FROM paymentdue_pdpd_agg
)

SELECT
    loans_payment_due_hashkey,
    SUM(tot_pd_pr)                                                  AS tot_pd_pr,
    SUM(tot_pd_int)                                                 AS tot_pd_int,
    SUM(tot_pd_pe)                                                  AS tot_pd_pe,
    SUM(tot_pd_ps)                                                  AS tot_pd_ps,
    MAX(max_pd_pr_days)                                             AS max_pd_pr_days,
    MAX(max_pd_in_days)                                             AS max_pd_in_days,
    MAX(max_pd_pe_days)                                             AS max_pd_pe_days,
    MAX(max_pd_ps_days)                                             AS max_pd_ps_days,
    {{ target_date_sql }}                                           AS source_event_date,
    current_timestamp                                             AS load_timestamp,
    concat('t24', '__', 't24_payment_due')                 AS record_source
FROM all_sources
GROUP BY loans_payment_due_hashkey
{% endset %}

{{ computed_satellite(
    hashkey_col=hashkey_col,
    computed_cols=computed_cols,
    raw_sql=raw_sql
) }}
