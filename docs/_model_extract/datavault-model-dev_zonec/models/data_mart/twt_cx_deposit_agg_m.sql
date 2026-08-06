{% set tgt = var('target_date') %}
{% set ym = tgt[:6] %}

{{
  config(
    materialized='incremental',
   incremental_strategy='append',
    pre_hook=[
      "delete from {{ this }} where ym = '" ~ ym ~ "'"
    ],
    skip_matched_step = true,
    auto_liquid_cluster = true,
    catalog = var('curated_catalog'),
    tags=['t24']
  )
}}

WITH calendar_dates AS (
    SELECT
        CASE 
            WHEN bsn_day_f = 1 THEN msr_prd_dt 
            ELSE last_wk_dt 
        END AS effective_date
    FROM {{ ref('calendar') }}
    WHERE msr_prd_dt BETWEEN date_trunc('month', to_date('{{ tgt }}', 'yyyyMMdd')) 
                         AND last_day(to_date('{{ tgt }}', 'yyyyMMdd'))
),

src AS (
    SELECT
        date_format(a.snapshot_date, 'yyyyMM') AS ym,
        a.customer_business_key AS customer_id,
        coalesce(crb_tieukhoan, account_business_key, loans_business_key) AS account_no,
        b.ngoaite AS currency,
        a.crb_gl AS gl,
        sum(CASE WHEN b.ngoaite != 'VND' THEN b.ngoaite1 ELSE b.noite END) AS agg_balance,
        sum(b.noite) AS agg_balance_lcy,
        max(b.source_event_date) AS max_date
    FROM {{ ref('bridge_account') }} a
    JOIN {{ ref('sat_crb_balance') }} b
      ON a.crb_hashkey = b.crb_hashkey
     AND a.snapshot_date = b.source_event_date
     AND b.source_event_date BETWEEN date_trunc('month', to_date('{{ tgt }}', 'yyyyMMdd')) 
                               AND to_date('{{ tgt }}', 'yyyyMMdd')
    JOIN calendar_dates aod
      ON a.snapshot_date = aod.effective_date
    WHERE a.snapshot_date BETWEEN date_trunc('month', to_date('{{ tgt }}', 'yyyyMMdd')) 
                               AND to_date('{{ tgt }}', 'yyyyMMdd')
      AND substring(a.crb_gl, 1, 2) IN ('41', '42', '43', '44')
    GROUP BY 1, 2, 3, 4, 5
)

SELECT *
FROM src
where customer_id is not null