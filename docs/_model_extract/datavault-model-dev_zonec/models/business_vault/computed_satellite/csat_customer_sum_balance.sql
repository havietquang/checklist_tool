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
    alias = 'csat_customer_sum_balance',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    skip_matched_step = true,
    unique_key = ['customer_hashkey', 'hashdiff', 'source_event_date'],
    tags = ['t24', 'customer', 'zonec', 'bv_zonec']
) }}

/*
========================================================================
COMPUTED SATELLITE: csat_customer_sum_balance
========================================================================
Tinh 4 cot so du theo tung khach hang (customer_hashkey): so_du_tien_gui, so_du_tien_vay, so_du_bao_lanh, so_du_lc.
Moi so tien deu quy doi ve VND qua fx_rate.

IMPORT CHUNG:
  - deleted_crb / deleted_customers / deleted_consumer_loan: loai
    hashkey co cdc_status moi nhat = 'D'.
  - fx_rate: ty gia quy doi ve VND (VND=1, ngoai te lay t_reval_rate,
    fallback t_mid_reval_rate).
  - gl_param + hub_crb: map tieukhoan/gl -> para_group (nhom san pham).
  - latest_*: lay record moi nhat den target_date cua tung sat nguon.

POPULATION & PHAN NHOM:
  - base_customer_all: toan bo KH con active = population cua output.
  - base_customer_crb: KH co link CRB active -> base_by_gl_param
    (hub_crb.gl JOIN gl_param) -> tach base_tiengui / base_tienvay /
    base_baolanh / base_lc theo para_group.

4 COT SO DU (moi cot = SUM cac nguon con):

  SO_DU_TIEN_GUI  (base_tiengui)  = account_balance + money_market
                                    + LD balance (sat_loans_information).

  SO_DU_TIEN_VAY  (base_tienvay)  = account_balance + money_market
                                    + LD balance
                                    + PD balance (hub_loans_payment_due,
                                      explode '::' ky han roi '!!' cau phan,
                                      lay t_pay_amt_outs).
                                    * tv_comb_balance (consumer loan, join
                                      thang customer_hashkey).

  SO_DU_BAO_LANH  (base_baolanh)  = md_deal value + account_balance.

  SO_DU_LC        (base_lc)       = LC value (LC KHONG co drawings)
                                    + drawings balance (LC CO drawings,
                                      SUM theo letter_of_credit_hashkey).
========================================================================
*/

{% set hashkey_col = 'customer_hashkey' %}
{% set target_date_sql = "to_date('" ~ var("target_date") ~ "', 'yyyyMMdd')" %}

{% set computed_cols = [
    {'alias': 'so_du_tien_gui'},
    {'alias': 'so_du_tien_vay'},
    {'alias': 'so_du_bao_lanh'},
    {'alias': 'so_du_lc'}
] %}

{% set raw_sql %}
WITH
-- ============================================================
-- [1] IMPORT TABLES: chi lay cac truong can thiet cua cac bang can su dung nhieu lan
-- ============================================================
gl_param AS (
    SELECT gl_nbr, para_group, gl_type
    FROM {{ source('tckh', 'gl_param') }}
),

-- Lay cac crb_hashkey da bi xoa tai target_date (cdc_status moi nhat = 'D')
deleted_crb AS (
    SELECT crb_hashkey
    FROM (
        SELECT
            crb_hashkey,
            cdc_status,
            ROW_NUMBER() OVER (PARTITION BY crb_hashkey ORDER BY source_event_date DESC) AS rn
        FROM {{ source('raw_vault','sts_hub_crb') }}
        WHERE source_event_date <= {{ target_date_sql }}
    )
    WHERE rn = 1 AND cdc_status = 'D'
),

hub_crb AS (
    SELECT crb_hashkey, gl, tieukhoan
    FROM {{ source('raw_vault','hub_crb') }} hub
    WHERE NOT EXISTS (
        SELECT 1 FROM deleted_crb del
        WHERE del.crb_hashkey = hub.crb_hashkey
    )
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

-- ============================================================
-- [2] LATEST RECORD: lay record moi nhat tinh den target_date
-- ============================================================
deleted_customers AS (
    SELECT customer_hashkey
    FROM (
        SELECT
            customer_hashkey,
            cdc_status,
            ROW_NUMBER() OVER (PARTITION BY customer_hashkey ORDER BY source_event_date DESC) AS rn
        FROM {{ source('raw_vault','sts_hub_customer') }}
        WHERE source_event_date <= {{ target_date_sql }}
    )
    WHERE rn = 1 AND cdc_status = 'D'
),

-- sat_account_balance la bang snapshot theo ngay (moi ngay 1 ban/key) -> lay dung source_event_date = target_date, khong can dedup lay ban moi nhat
latest_sat_account_balance AS (
    SELECT account_hashkey, t_currency, t_open_actual_bal
    FROM {{ source('raw_vault','sat_account_balance') }}
    WHERE source_event_date = {{ target_date_sql }}
),

latest_sat_money_market_information AS (
    SELECT money_market_hashkey, t_currency, t_principal
    FROM {{ source('raw_vault','sat_money_market_information') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY money_market_hashkey ORDER BY source_event_date DESC) = 1
),

latest_sat_loans_information AS (
    SELECT loans_hashkey, t_currency, t_amount
    FROM {{ source('raw_vault','sat_loans_information') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY loans_hashkey ORDER BY source_event_date DESC) = 1
),

latest_sat_loans_payment_due_information AS (
    SELECT loans_payment_due_hashkey, t_currency, t_payment_dte_due
    FROM {{ source('raw_vault','sat_loans_payment_due_information') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY loans_payment_due_hashkey ORDER BY source_event_date DESC) = 1
),

latest_sat_loans_payment_due_overdue AS (
    SELECT loans_payment_due_hashkey, t_pay_type, t_pay_amt_outs
    FROM {{ source('raw_vault','sat_loans_payment_due_overdue') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY loans_payment_due_hashkey ORDER BY source_event_date DESC) = 1
),

-- Explode t_payment_dte_due ('::', tu index 10) roi explode t_pay_type ('!!')
pd_sch_exploded AS (
    SELECT
        info.loans_payment_due_hashkey,
        info.t_currency,
        get(split(ovd.t_pay_type,     '::'), sch_pos) AS t_pay_type_sch,
        get(split(ovd.t_pay_amt_outs, '::'), sch_pos) AS t_pay_amt_outs_sch
    FROM latest_sat_loans_payment_due_information info
    JOIN latest_sat_loans_payment_due_overdue ovd
        ON ovd.loans_payment_due_hashkey = info.loans_payment_due_hashkey
    LATERAL VIEW posexplode(split(info.t_payment_dte_due, '::')) t AS sch_pos, t_pay_dte_due_sch
    WHERE sch_pos >= 10
),

pd_comp_exploded AS (
    SELECT
        s.loans_payment_due_hashkey,
        s.t_currency,
        get(split(s.t_pay_amt_outs_sch, '!!'), comp_pos) AS t_pay_amt_outs_comp
    FROM pd_sch_exploded s
    LATERAL VIEW posexplode(split(s.t_pay_type_sch, '!!')) c AS comp_pos, t_pay_type_comp
),

latest_sat_consumer_loan AS (
    SELECT consumer_loan_hashkey, currency, on_due_principal
    FROM {{ source('raw_vault','sat_consumer_loan') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY consumer_loan_hashkey ORDER BY source_event_date DESC) = 1
),

latest_sat_md_deal_information AS (
    SELECT md_deal_hashkey, t_currency
    FROM {{ source('raw_vault','sat_md_deal_information') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY md_deal_hashkey ORDER BY source_event_date DESC) = 1
),

latest_sat_md_deal_value AS (
    SELECT md_deal_hashkey, t_principal_amount
    FROM {{ source('raw_vault','sat_md_deal_value') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY md_deal_hashkey ORDER BY source_event_date DESC) = 1
),

-- link_drawings_letter_of_credit khong co effsat -> group by hashkey dau (drawings_hashkey)
-- lay ban ghi co max source_event_date de tranh lay phai mapping letter_of_credit_hashkey da cu/stale
latest_link_drawings_letter_of_credit AS (
    SELECT drawings_hashkey, letter_of_credit_hashkey
    FROM {{ source('raw_vault','link_drawings_letter_of_credit') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY drawings_hashkey
        ORDER BY source_event_date DESC
    ) = 1
),

latest_sat_letter_of_credit_value AS (
    SELECT letter_of_credit_hashkey, t_lc_currency, t_liability_amt
    FROM {{ source('raw_vault','sat_letter_of_credit_value') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY letter_of_credit_hashkey ORDER BY source_event_date DESC) = 1
),

latest_sat_drawings_information AS (
    SELECT drawings_hashkey, t_draw_currency, t_document_amount
    FROM {{ source('raw_vault','sat_drawings_information') }}
    WHERE source_event_date <= {{ target_date_sql }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY drawings_hashkey ORDER BY source_event_date DESC) = 1
),

-- ============================================================
-- [3] BASE CUSTOMER
-- base_customer_all : toan bo khach hang con hoat dong (loai da xoa) - dung lam population cho ca report va cho COMB
-- base_customer_crb : khach hang co CRB link active - chi dung de tinh TIENGUI/TIENVAY/BAOLANH/LC qua GL_PARAM
-- ============================================================
base_customer_all AS (
    SELECT hc.customer_hashkey
    FROM {{ source('raw_vault','hub_customer') }} hc
    WHERE NOT EXISTS (
        SELECT 1 FROM deleted_customers dc
        WHERE dc.customer_hashkey = hc.customer_hashkey
    )
),

base_customer_crb AS (
    SELECT
        bca.customer_hashkey,
        lcc.crb_hashkey
    FROM base_customer_all bca
    INNER JOIN {{ source('raw_vault','link_crb_customer') }} lcc
        ON bca.customer_hashkey = lcc.customer_hashkey
    INNER JOIN (
        SELECT link_crb_customer_hashkey, active_flag
        FROM {{ source('raw_vault','effsat_link_crb_customer') }}
        WHERE source_event_date <= {{ target_date_sql }}
        QUALIFY ROW_NUMBER() OVER (PARTITION BY link_crb_customer_hashkey ORDER BY source_event_date DESC) = 1
    ) efs_lcc
        ON efs_lcc.link_crb_customer_hashkey = lcc.link_crb_customer_hashkey
       AND efs_lcc.active_flag = 1
),

-- ============================================================
-- [4] TINH TOAN SO DU THEO TUNG NHOM SAN PHAM
-- base_by_gl_param: gop hub_crb + gl_param 1 lan, base_<nhom> chi loc para_group
-- ============================================================
base_by_gl_param AS (
    SELECT
        bc.customer_hashkey,
        hcrb.tieukhoan,
        gp.para_group,
        gp.gl_nbr,
        gp.gl_type
    FROM base_customer_crb bc
    INNER JOIN hub_crb hcrb ON bc.crb_hashkey = hcrb.crb_hashkey
    INNER JOIN gl_param gp ON hcrb.gl = gp.gl_nbr
),

base_tiengui AS (
    SELECT customer_hashkey, tieukhoan
    FROM base_by_gl_param
    WHERE para_group = 'TIENGUI'
      AND (gl_nbr IN ('4231', '4241') OR gl_type NOT IN ('TGTT1KKH'))
),

base_tienvay AS (
    SELECT customer_hashkey, tieukhoan
    FROM base_by_gl_param
    WHERE para_group = 'TIENVAY'
),

base_baolanh AS (
    SELECT customer_hashkey, tieukhoan
    FROM base_by_gl_param
    WHERE para_group = 'BAOLANH'
),

base_lc AS (
    SELECT customer_hashkey, tieukhoan
    FROM base_by_gl_param
    WHERE para_group = 'LC'
),

-- ============================================================
-- SO_DU_TIEN_GUI
-- ============================================================
tg_account_balance AS (
    SELECT
        bc.customer_hashkey,
        COALESCE(CAST(sat.t_open_actual_bal AS decimal(19,4)) * fx.rate, CAST(0 AS decimal(19,4))) AS amount
    FROM base_tiengui bc
    LEFT JOIN {{ source('raw_vault','hub_account') }} ha ON bc.tieukhoan = ha.business_key
    LEFT JOIN latest_sat_account_balance sat ON sat.account_hashkey = ha.account_hashkey
    LEFT JOIN fx_rate fx ON fx.currency_id = sat.t_currency
),

-- SO_DU_TIEN_GUI: Money Market Balance
tg_money_market_balance AS (
    SELECT
        bc.customer_hashkey,
        COALESCE(CAST(sat.t_principal AS decimal(19,4)) * fx.rate, CAST(0 AS decimal(19,4))) AS amount
    FROM base_tiengui bc
    LEFT JOIN {{ source('raw_vault','hub_money_market') }} hmm ON bc.tieukhoan = hmm.business_key
    LEFT JOIN latest_sat_money_market_information sat ON sat.money_market_hashkey = hmm.money_market_hashkey
    LEFT JOIN fx_rate fx ON fx.currency_id = sat.t_currency
),

-- SO_DU_TIEN_GUI: LD Balance
tg_ld_balance AS (
    SELECT
        bc.customer_hashkey,
        COALESCE(CAST(sat.t_amount AS decimal(19,4)) * fx.rate, CAST(0 AS decimal(19,4))) AS amount
    FROM base_tiengui bc
    LEFT JOIN {{ source('raw_vault','hub_loans') }} hl ON bc.tieukhoan = hl.business_key
    LEFT JOIN latest_sat_loans_information sat ON sat.loans_hashkey = hl.loans_hashkey
    LEFT JOIN fx_rate fx ON fx.currency_id = sat.t_currency
),

-- ============================================================
-- SO_DU_TIEN_VAY
-- ============================================================
tv_account_balance AS (
    SELECT
        bc.customer_hashkey,
        COALESCE(CAST(sat.t_open_actual_bal AS decimal(19,4)) * fx.rate, CAST(0 AS decimal(19,4))) AS amount
    FROM base_tienvay bc
    LEFT JOIN {{ source('raw_vault','hub_account') }} ha ON bc.tieukhoan = ha.business_key
    LEFT JOIN latest_sat_account_balance sat ON sat.account_hashkey = ha.account_hashkey
    LEFT JOIN fx_rate fx ON fx.currency_id = sat.t_currency
),

-- SO_DU_TIEN_VAY: Money Market Balance
tv_money_market_balance AS (
    SELECT
        bc.customer_hashkey,
        COALESCE(CAST(sat.t_principal AS decimal(19,4)) * fx.rate, CAST(0 AS decimal(19,4))) AS amount
    FROM base_tienvay bc
    LEFT JOIN {{ source('raw_vault','hub_money_market') }} hmm ON bc.tieukhoan = hmm.business_key
    LEFT JOIN latest_sat_money_market_information sat ON sat.money_market_hashkey = hmm.money_market_hashkey
    LEFT JOIN fx_rate fx ON fx.currency_id = sat.t_currency
),

-- SO_DU_TIEN_VAY: LD Balance (tinh cho tat ca loans, cong don voi PD Balance)
tv_ld_balance AS (
    SELECT
        bc.customer_hashkey,
        COALESCE(CAST(sat.t_amount AS decimal(19,4)) * fx.rate, CAST(0 AS decimal(19,4))) AS amount
    FROM base_tienvay bc
    LEFT JOIN {{ source('raw_vault','hub_loans') }} hl ON bc.tieukhoan = hl.business_key
    LEFT JOIN latest_sat_loans_information sat ON sat.loans_hashkey = hl.loans_hashkey
    LEFT JOIN fx_rate fx ON fx.currency_id = sat.t_currency
),

-- SO_DU_TIEN_VAY: PD Balance (tu hub_loans_payment_due, da explode multi-value)
tv_pd_balance AS (
    SELECT
        bc.customer_hashkey,
        COALESCE(TRY_CAST(e.t_pay_amt_outs_comp AS decimal(19,4)) * fx.rate, CAST(0 AS decimal(19,4))) AS amount
    FROM base_tienvay bc
    LEFT JOIN {{ source('raw_vault','hub_loans_payment_due') }} hlpd ON bc.tieukhoan = hlpd.business_key
    LEFT JOIN pd_comp_exploded e
        ON e.loans_payment_due_hashkey = hlpd.loans_payment_due_hashkey
    LEFT JOIN fx_rate fx ON fx.currency_id = e.t_currency
),


-- SO_DU_TIEN_VAY: COMB Balance (consumer loan, khong qua GL_PARAM/hub_crb, join thang tu customer_hashkey)

-- Lay cac consumer_loan_hashkey da bi xoa tai target_date (cdc_status moi nhat = 'D')
deleted_consumer_loan AS (
    SELECT consumer_loan_hashkey
    FROM (
        SELECT
            consumer_loan_hashkey,
            cdc_status,
            ROW_NUMBER() OVER (PARTITION BY consumer_loan_hashkey ORDER BY source_event_date DESC) AS rn
        FROM {{ source('raw_vault','sts_hub_consumer_loan') }}
        WHERE source_event_date <= {{ target_date_sql }}
    )
    WHERE rn = 1 AND cdc_status = 'D'
),

tv_comb_balance AS (
    SELECT
        bc.customer_hashkey,
        COALESCE(CAST(sat.on_due_principal AS decimal(19,4)) * fx.rate, CAST(0 AS decimal(19,4))) AS amount
    FROM base_customer_all bc
    INNER JOIN {{ source('raw_vault','link_consumer_loan_customer') }} lccl ON lccl.customer_hashkey = bc.customer_hashkey
    LEFT JOIN {{ source('raw_vault','hub_consumer_loan') }} hcl ON hcl.consumer_loan_hashkey = lccl.consumer_loan_hashkey
        AND NOT EXISTS (
            SELECT 1 FROM deleted_consumer_loan del
            WHERE del.consumer_loan_hashkey = hcl.consumer_loan_hashkey
        )
    INNER JOIN latest_sat_consumer_loan sat ON sat.consumer_loan_hashkey = hcl.consumer_loan_hashkey
    LEFT JOIN fx_rate fx ON fx.currency_id = sat.currency
),


-- ============================================================
-- SO_DU_BAO_LANH
-- ============================================================
bl_md_deal_balance AS (
    SELECT
        bc.customer_hashkey,
        COALESCE(CAST(val.t_principal_amount AS decimal(19,4)) * fx.rate, CAST(0 AS decimal(19,4))) AS amount
    FROM base_baolanh bc
    LEFT JOIN {{ source('raw_vault','hub_md_deal') }} hmd ON bc.tieukhoan = hmd.business_key
    LEFT JOIN latest_sat_md_deal_information info ON info.md_deal_hashkey = hmd.md_deal_hashkey
    LEFT JOIN latest_sat_md_deal_value val ON val.md_deal_hashkey = hmd.md_deal_hashkey
    LEFT JOIN fx_rate fx ON fx.currency_id = info.t_currency
),

-- SO_DU_BAO_LANH: Account Balance
bl_account_balance AS (
    SELECT
        bc.customer_hashkey,
        COALESCE(CAST(sat.t_open_actual_bal AS decimal(19,4)) * fx.rate, CAST(0 AS decimal(19,4))) AS amount
    FROM base_baolanh bc
    LEFT JOIN {{ source('raw_vault','hub_account') }} ha ON bc.tieukhoan = ha.business_key
    LEFT JOIN latest_sat_account_balance sat ON sat.account_hashkey = ha.account_hashkey
    LEFT JOIN fx_rate fx ON fx.currency_id = sat.t_currency
),

-- ============================================================
-- SO_DU_LC
-- ============================================================
lc_balance AS (
    SELECT
        bc.customer_hashkey,
        COALESCE(CAST(val.t_liability_amt AS decimal(19,4)) * fx.rate, CAST(0 AS decimal(19,4))) AS amount
    FROM base_lc bc
    LEFT JOIN {{ source('raw_vault','hub_letter_of_credit') }} hloc ON bc.tieukhoan = hloc.business_key
    LEFT JOIN latest_link_drawings_letter_of_credit ldloc
        ON ldloc.letter_of_credit_hashkey = hloc.letter_of_credit_hashkey
    LEFT JOIN latest_sat_letter_of_credit_value val
        ON val.letter_of_credit_hashkey = hloc.letter_of_credit_hashkey
    LEFT JOIN fx_rate fx ON fx.currency_id = val.t_lc_currency
    WHERE ldloc.letter_of_credit_hashkey IS NULL
),

-- SO_DU_LC: Drawings Balance (co drawings, SUM theo letter_of_credit_hashkey)
lc_drawings_balance AS (
    SELECT
        bc.customer_hashkey,
        hloc.letter_of_credit_hashkey,
        SUM(
            COALESCE(CAST(sat.t_document_amount AS decimal(19,4)) * fx.rate, CAST(0 AS decimal(19,4)))
        ) AS amount
    FROM base_lc bc
    LEFT JOIN {{ source('raw_vault','hub_letter_of_credit') }} hloc ON bc.tieukhoan = hloc.business_key
    INNER JOIN latest_link_drawings_letter_of_credit ldloc
        ON ldloc.letter_of_credit_hashkey = hloc.letter_of_credit_hashkey
    LEFT JOIN {{ source('raw_vault','hub_drawings') }} hd ON hd.drawings_hashkey = ldloc.drawings_hashkey
    LEFT JOIN latest_sat_drawings_information sat ON sat.drawings_hashkey = hd.drawings_hashkey
    LEFT JOIN fx_rate fx ON fx.currency_id = sat.t_draw_currency
    GROUP BY bc.customer_hashkey, hloc.letter_of_credit_hashkey
),

-- ============================================================
-- [5] TONG HOP SO DU THEO CUSTOMER
-- ============================================================
agg_tien_gui AS (
    SELECT customer_hashkey, SUM(amount) AS so_du_tien_gui
    FROM (
        SELECT customer_hashkey, amount FROM tg_account_balance
        UNION ALL
        SELECT customer_hashkey, amount FROM tg_money_market_balance
        UNION ALL
        SELECT customer_hashkey, amount FROM tg_ld_balance
    )
    GROUP BY customer_hashkey
),

agg_tien_vay AS (
    SELECT customer_hashkey, SUM(amount) AS so_du_tien_vay
    FROM (
        SELECT customer_hashkey, amount FROM tv_account_balance
        UNION ALL
        SELECT customer_hashkey, amount FROM tv_money_market_balance
        UNION ALL
        SELECT customer_hashkey, amount FROM tv_ld_balance
        UNION ALL
        SELECT customer_hashkey, amount FROM tv_pd_balance
        UNION ALL
        SELECT customer_hashkey, amount FROM tv_comb_balance
    )
    GROUP BY customer_hashkey
),

agg_bao_lanh AS (
    SELECT customer_hashkey, SUM(amount) AS so_du_bao_lanh
    FROM (
        SELECT customer_hashkey, amount FROM bl_md_deal_balance
        UNION ALL
        SELECT customer_hashkey, amount FROM bl_account_balance
    )
    GROUP BY customer_hashkey
),

agg_lc AS (
    SELECT customer_hashkey, SUM(amount) AS so_du_lc
    FROM (
        SELECT customer_hashkey, CAST(amount AS decimal(38,10)) AS amount FROM lc_balance
        UNION ALL
        SELECT customer_hashkey, CAST(amount AS decimal(38,10)) AS amount FROM lc_drawings_balance
    )
    GROUP BY customer_hashkey
)

SELECT
    bc.customer_hashkey,
    COALESCE(tg.so_du_tien_gui, CAST(0 AS decimal(38,10)))  AS so_du_tien_gui,
    COALESCE(tv.so_du_tien_vay, CAST(0 AS decimal(38,10)))  AS so_du_tien_vay,
    COALESCE(bl.so_du_bao_lanh, CAST(0 AS decimal(38,10)))  AS so_du_bao_lanh,
    COALESCE(lc.so_du_lc,       CAST(0 AS decimal(38,10)))  AS so_du_lc,
    {{ target_date_sql }} AS source_event_date,
    current_timestamp                               AS load_timestamp,
    concat('t24', '__', 't24_customer')             AS record_source
FROM base_customer_all bc
LEFT JOIN agg_tien_gui  tg ON tg.customer_hashkey = bc.customer_hashkey
LEFT JOIN agg_tien_vay  tv ON tv.customer_hashkey = bc.customer_hashkey
LEFT JOIN agg_bao_lanh  bl ON bl.customer_hashkey = bc.customer_hashkey
LEFT JOIN agg_lc        lc ON lc.customer_hashkey = bc.customer_hashkey
{% endset %}

{{ computed_satellite(
    hashkey_col=hashkey_col,
    computed_cols=computed_cols,
    raw_sql=raw_sql
) }}
