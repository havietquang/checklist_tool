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


WITH 
-- [OPT] pit_customer: scan 1 lần, dùng cho cả debit (pc_de) lẫn credit (pc_cre)
pit_customer_cte AS (
  SELECT customer_hashkey, snapshot_date, sat_customer_information_src_ev_dt
  FROM {{ ref('pit_customer') }}
  WHERE snapshot_date = to_date('{{ tgt }}', 'yyyyMMdd')
),
-- [OPT] hub_customer: scan 1 lần, dùng cho cả hcc lẫn hcd
hub_customer_cte AS (
  SELECT customer_hashkey, business_key
  FROM {{ ref('hub_customer') }} 
),
-- [OPT] sat_customer_information: scan 1 lần, dùng cho cả scic lẫn scid
sat_customer_info_cte AS (
  SELECT customer_hashkey, source_event_date, name_1
  FROM {{ ref('sat_customer_information') }} 
  WHERE source_event_date <= to_date('{{ tgt }}', 'yyyyMMdd')
),
-- [OPT] ref_currency: scan 1 lần, dùng cho cả sci_debit lẫn sci_credit
ref_currency_cte AS (
  SELECT id, data_date, T_MID_REVAL_RATE
  FROM {{ ref('ref_currency') }} 
),
source_funds_transfer AS (
    SELECT /*+ BROADCAST(hcc, hcd, sci_debit, sci_credit) */
        a.snapshot_date AS date_cob,
        a.funds_transfer_hashkey,
        a.account_debit_hashkey,
        a.account_credit_hashkey,
        a.customer_debit_hashkey,
        a.customer_credit_hashkey,
        a.branch_hashkey,
        a.funds_transfer_business_key AS ft_no,
        b.t_transaction_type AS transaction_type,
        NULL AS transaction_code,

        CASE
            WHEN b.t_transaction_type IN ('BCI2','BCWB','BCSS','BCLO','OTVC','OTOP') THEN 'OUT-DOMESTIC'
            WHEN b.t_transaction_type IN ('BIIB','ITVC','ACIX') THEN 'IN-DOMESTIC'
            WHEN b.t_transaction_type = 'IT' THEN 'IN-OVERSEAS'
            WHEN b.t_transaction_type IN ('OT03','OT22') THEN 'OUT-OVERSEAS'
            WHEN b.t_transaction_type LIKE 'AC%' THEN 'INTERNAL'
        END AS in_out,

        CASE
            WHEN b.t_transaction_type IN ('BCI2','BCWB','BCSS','BCLO','OTVC') THEN d.t_bc_bank_sort_code
            WHEN b.t_transaction_type = 'OTOP' THEN c.t_bidv_recvrbank
            ELSE NULL
        END AS bc_bank_sort_code,

        CASE
            WHEN b.t_transaction_type IN ('BCI2','BCWB','BCSS','BCLO','OTVC') THEN COALESCE(c.t_r_ci_code, d.t_bc_bank_sort_code)
            WHEN b.t_transaction_type = 'OTOP' THEN c.t_bidv_recvrbank
            WHEN b.t_transaction_type = 'OT03' AND LEFT(e.t_acct_with_bank, 2) = 'SW' THEN SUBSTR(e.t_acct_with_bank, 4)
            WHEN b.t_transaction_type = 'OT03' AND LEFT(e.t_acct_with_bank, 2) != 'SW' THEN e.t_acct_with_bank
            ELSE NULL
        END AS receiver_bank_code,

        c.t_ordering_bank AS ordering_bank_code,
        f.t_classify_code AS classify_code,
        a.branch_business_key AS branch_code,
        b.t_debit_currency AS dr_currency,
        b.t_amount_debited AS dr_amount,
        b.t_loc_amt_debited AS dr_lcy_amount,
        b.t_credit_currency AS cr_currency,
        b.t_amount_credited AS cr_amount,
        b.t_loc_amt_credited AS cr_lcy_amount,
        COALESCE(b.t_debit_currency, b.t_credit_currency) AS currency,
        b.t_debit_value_date AS trade_date,
        b.t_credit_value_date AS value_date,
        d.t_border_trans AS border_transaction,
        g.t_ft_out_purpose AS purpose_code,
        g.t_inputter AS inputter,
        g.t_authoriser AS authoriser,
        c.t_ben_our_charges AS ben_our_charges,
        COALESCE(d.t_msg_narrative, b.t_payment_details) AS payment_detail,
        g.t_mkfile_com AS mkfile_com,
        f.t_commission_code AS commission_code,
        f.t_commission_type AS commission_type,
        f.t_commission_amt AS commission_amt,
        b.t_debit_their_ref AS debit_their_ref,
        d.t_eft_country,
        e.t_acct_with_bank,
        e.t_acct_with_bank_acc,
        c.t_ordering_cust,
        c.t_cu_d_ord_cpt,
        c.t_in_ben_customer,
        c.t_ben_customer,
        e.t_in_ben_acct_no,
        e.t_ben_acct_no,
        cast(hcd.business_key as string) AS customer_debit_business_key,
        cast(hcc.business_key as string) AS customer_credit_business_key,
        a.account_debit_business_key,
        a.account_credit_business_key,
        g.t_date_time,

        CASE
            WHEN b.t_transaction_type = 'IT' THEN d.t_eft_country
            WHEN b.t_transaction_type IN ('OT03','OT22') AND SUBSTR(e.t_acct_with_bank_acc, 2, 2) = 'FW' THEN 'US'
            WHEN b.t_transaction_type IN ('OT03','OT22') AND SUBSTR(e.t_acct_with_bank_acc, 2, 2) = 'AU' THEN 'AU'
            WHEN b.t_transaction_type IN ('OT03','OT22') AND SUBSTR(e.t_acct_with_bank_acc, 2, 2) = 'SC' THEN 'UK'
            WHEN b.t_transaction_type IN ('OT03','OT22') AND e.t_acct_with_bank IS NOT NULL THEN SUBSTR(e.t_acct_with_bank, 8, 2)
            ELSE NULL
        END AS country_code,

        CASE
            WHEN b.t_transaction_type IN ('BCI2','BCWB','BCSS','BCLO','OTOP') THEN c.t_bidv_recvrbank
            WHEN b.t_transaction_type = 'OTVC' THEN NULL
            WHEN b.t_transaction_type = 'OT03' THEN c.t_bidv_recvrbank
            ELSE NULL
        END AS receiver_bank_ref_code,

        d.t_receiving_addr,
        scid.name_1 AS customer_debit_name,
        scic.name_1 AS customer_credit_name,
        sci_debit.T_MID_REVAL_RATE AS dr_mid_reval_rate,
        sci_credit.T_MID_REVAL_RATE AS cr_mid_reval_rate,
        lftcc.clearing_citad_hashkey,
        hcc_citad.business_key AS clearing_id,
        sccpi.t_o_pci_code

    FROM {{ ref('bridge_ft') }} a

    LEFT JOIN pit_customer_cte pc_de
        ON a.customer_debit_hashkey = pc_de.customer_hashkey
       AND pc_de.snapshot_date = a.snapshot_date

    LEFT JOIN pit_customer_cte pc_cre
        ON a.customer_credit_hashkey = pc_cre.customer_hashkey
       AND pc_cre.snapshot_date = a.snapshot_date

    LEFT JOIN {{ ref('sat_funds_transfer_information') }} b
        ON a.funds_transfer_hashkey = b.funds_transfer_hashkey
       AND b.source_event_date = a.snapshot_date
       and b.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')

    LEFT JOIN {{ ref('sat_funds_transfer_party') }} c
        ON a.funds_transfer_hashkey = c.funds_transfer_hashkey
       AND c.source_event_date = a.snapshot_date
       and c.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')

    LEFT JOIN {{ ref('sat_funds_transfer_other') }} d
        ON a.funds_transfer_hashkey = d.funds_transfer_hashkey
       AND d.source_event_date = a.snapshot_date
       AND d.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')

    LEFT JOIN {{ ref('sat_funds_transfer_account') }}  e
        ON a.funds_transfer_hashkey = e.funds_transfer_hashkey
       AND e.source_event_date = a.snapshot_date
       and e.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')

    LEFT JOIN {{ ref('sat_funds_transfer_fee') }} f
        ON a.funds_transfer_hashkey = f.funds_transfer_hashkey
       AND f.source_event_date = a.snapshot_date
       and f.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')

    LEFT JOIN {{ ref('sat_funds_transfer_system') }} g
        ON a.funds_transfer_hashkey = g.funds_transfer_hashkey
       AND g.source_event_date = a.snapshot_date
       and g.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')

    LEFT JOIN {{ ref('link_funds_transfer_credit_customer') }}  lcc
        ON a.funds_transfer_hashkey = lcc.funds_transfer_hashkey
       AND lcc.source_event_date = a.snapshot_date
       and lcc.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')

    LEFT JOIN hub_customer_cte hcc
        ON lcc.customer_hashkey = hcc.customer_hashkey

    LEFT JOIN {{ ref('link_funds_transfer_debit_customer') }} lcd
        ON a.funds_transfer_hashkey = lcd.funds_transfer_hashkey
       AND lcd.source_event_date = a.snapshot_date 
       and lcd.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')

    LEFT JOIN hub_customer_cte hcd
        ON lcd.customer_hashkey = hcd.customer_hashkey

    LEFT JOIN {{ ref('sat_customer_information') }} scic
        ON a.customer_credit_hashkey = scic.customer_hashkey
       AND scic.source_event_date = pc_cre.sat_customer_information_src_ev_dt

    LEFT JOIN {{ ref('sat_customer_information') }} scid
        ON a.customer_debit_hashkey = scid.customer_hashkey
       AND scid.source_event_date = pc_de.sat_customer_information_src_ev_dt

    LEFT JOIN ref_currency_cte sci_debit
        ON b.t_debit_currency = sci_debit.id
       AND sci_debit.data_date = DATE_FORMAT(a.snapshot_date, 'yyyyMMdd')

    LEFT JOIN ref_currency_cte sci_credit
        ON b.t_credit_currency = sci_credit.id
       AND sci_credit.data_date = DATE_FORMAT(a.snapshot_date, 'yyyyMMdd')

    LEFT JOIN {{ ref('link_funds_transfer_clearing_citad') }} lftcc
        ON a.funds_transfer_hashkey = lftcc.funds_transfer_hashkey
       AND lftcc.source_event_date = a.snapshot_date
       and lftcc.source_event_date = to_date('{{ tgt }}', 'yyyyMMdd')

    LEFT JOIN {{ ref('hub_clearing_citad') }} hcc_citad
        ON lftcc.clearing_citad_hashkey = hcc_citad.clearing_citad_hashkey
       AND hcc_citad.source_event_date = a.snapshot_date

    LEFT JOIN {{ ref('sat_clearing_citad_payment_information') }} sccpi
        ON lftcc.clearing_citad_hashkey = sccpi.clearing_citad_hashkey
       AND sccpi.source_event_date = a.snapshot_date

    WHERE a.snapshot_date = to_date('{{ tgt }}', 'yyyyMMdd')
)

SELECT /*+ BROADCAST(ref_bsc, ref_bsc_1, ref_bsc_2, ref_bsc_3, ref_db, ref_db_1, rtco, ref_purpose) */
    s.date_cob AS date_cob,
    s.ft_no,
    s.transaction_type,
    s.in_out,
    s.bc_bank_sort_code,
    ref_bsc.ref_description AS bc_bank_sort_name,
    s.receiver_bank_code,

    CASE
        WHEN s.transaction_type IN ('BCI2','BCWB','BCSS','BCLO','OTOP') THEN ref_bsc_1.ref_description
        WHEN s.transaction_type = 'OTVC' THEN s.t_receiving_addr
        WHEN s.transaction_type = 'OT03' THEN COALESCE(ref_db.ref_description, s.t_acct_with_bank)
        ELSE NULL
    END AS receiver_bank_name,

    s.ordering_bank_code,

    CASE
        WHEN s.in_out = 'IN-DOMESTIC' THEN ref_bsc_2.ref_description
        WHEN s.in_out = 'IN-OVERSEAS' THEN COALESCE(ref_db_1.ref_description, s.ordering_bank_code)
        ELSE NULL
    END AS ordering_bank_name,

    s.clearing_id,
    s.classify_code,
    s.country_code,
    rtco.ref_description AS country_name,

    CASE
        WHEN SUBSTR(s.in_out, 1, 2) = 'IN' THEN cast(s.customer_credit_business_key as string)
        WHEN SUBSTR(s.in_out, 1, 3) = 'OUT' THEN cast(s.customer_debit_business_key as string)
    END AS customer_id,

    s.branch_code,
    s.dr_currency,
    s.account_debit_business_key AS dr_account,
    s.dr_amount,
    s.dr_lcy_amount,

    CASE
        WHEN s.dr_currency = 'USD' THEN s.dr_lcy_amount
        WHEN s.dr_currency = 'VND' THEN s.dr_lcy_amount / TRY_CAST(s.dr_mid_reval_rate AS DECIMAL)
        WHEN s.dr_currency NOT IN ('USD','VND') THEN s.dr_lcy_amount / (
            CASE
                WHEN s.dr_currency = 'VND' THEN 1
                WHEN INSTR(s.dr_mid_reval_rate, '::') > 1
                    THEN TRY_CAST(SUBSTR(s.dr_mid_reval_rate, 1, INSTR(s.dr_mid_reval_rate, '::') - 1) AS DECIMAL)
                ELSE TRY_CAST(s.dr_mid_reval_rate AS DECIMAL)
            END
        )
    END AS dr_usd_amount,

    s.cr_currency,
    s.account_credit_business_key AS cr_account,
    s.cr_amount,
    s.cr_lcy_amount,

    CASE
        WHEN s.cr_currency = 'USD' THEN s.cr_lcy_amount
        WHEN s.cr_currency = 'VND' THEN s.cr_lcy_amount / TRY_CAST(s.cr_mid_reval_rate AS DECIMAL)
        WHEN s.cr_currency NOT IN ('USD','VND') THEN s.cr_lcy_amount / (
            CASE
                WHEN s.cr_currency = 'VND' THEN 1
                WHEN INSTR(s.cr_mid_reval_rate, '::') > 1
                    THEN TRY_CAST(SUBSTR(s.cr_mid_reval_rate, 1, INSTR(s.cr_mid_reval_rate, '::') - 1) AS DECIMAL)
                ELSE TRY_CAST(s.cr_mid_reval_rate AS DECIMAL)
            END
        )
    END AS cr_usd_amount,

    s.currency,
    s.trade_date,
    s.value_date,

    CASE
        WHEN s.in_out IN ('IN-DOMESTIC','OUT-DOMESTIC') THEN s.t_ordering_cust
        WHEN s.in_out IN ('IN-OVERSEAS','OUT-OVERSEAS') THEN s.t_cu_d_ord_cpt
        WHEN s.in_out = 'INTERNAL' THEN s.customer_debit_name
    END AS ordering_cust,

    CASE
        WHEN s.in_out = 'IN-OVERSEAS' THEN COALESCE(s.t_ben_customer, s.t_in_ben_customer)
        WHEN s.in_out = 'IN-DOMESTIC' THEN s.t_in_ben_customer
        WHEN s.t_ben_customer IS NOT NULL THEN s.t_ben_customer
        WHEN s.t_ben_customer IS NULL AND s.transaction_type = 'OT22' THEN s.customer_debit_name
        WHEN s.t_ben_customer IS NULL AND s.transaction_type != 'OT22' THEN s.customer_credit_name
    END AS beneficiary,

    s.border_transaction,
    s.purpose_code,
    ref_purpose.ref_description AS purpose_name,
    s.inputter,
    s.authoriser,
    TRY_TO_TIMESTAMP(SPLIT_PART(s.t_date_time, '::', 1), 'yyMMddHHmm') AS t24_commit_time,
    TRY_TO_TIMESTAMP(SPLIT_PART(s.t_date_time, '::', 2), 'yyMMddHHmm') AS authorise_time,
    s.ben_our_charges,
    s.payment_detail,
    s.mkfile_com,

    CASE
        WHEN s.in_out = 'IN-OVERSEAS' THEN COALESCE(s.t_ben_acct_no, s.t_in_ben_acct_no)
        WHEN s.in_out = 'IN-DOMESTIC' THEN s.t_in_ben_acct_no
        WHEN s.t_ben_customer IS NOT NULL THEN s.t_ben_customer
        WHEN s.t_ben_customer IS NULL AND s.transaction_type = 'OT22' THEN s.account_debit_business_key
        WHEN s.t_ben_customer IS NULL AND s.transaction_type != 'OT22' THEN s.account_credit_business_key
    END AS beneficiary_account,

    s.commission_code,
    s.commission_type,
    s.debit_their_ref,

    CASE
        WHEN s.transaction_type IN ('BIIB','ITVC') THEN s.t_o_pci_code
        ELSE NULL
    END AS ordering_bank_code_indirect,

    ref_bsc_3.ref_description AS ordering_bank_name_indirect,
    s.customer_credit_business_key AS credit_customer,
    s.customer_debit_business_key AS debit_customer

FROM source_funds_transfer s

LEFT JOIN {{ ref('ref_t24_bc_sort_code') }} ref_bsc
    ON s.bc_bank_sort_code = ref_bsc.ref_code

LEFT JOIN {{ ref('ref_t24_bc_sort_code') }} ref_bsc_1
    ON s.receiver_bank_ref_code = ref_bsc_1.ref_code

LEFT JOIN {{ ref('ref_t24_de_bic') }} ref_db
    ON s.receiver_bank_ref_code = ref_db.ref_code

LEFT JOIN {{ ref('ref_t24_bc_sort_code') }} ref_bsc_2
    ON s.ordering_bank_code = ref_bsc_2.ref_code

LEFT JOIN {{ ref('ref_t24_de_bic') }} ref_db_1
    ON s.ordering_bank_code = ref_db_1.ref_code

LEFT JOIN {{ ref('ref_t24_country') }} rtco
    ON s.country_code = rtco.ref_code

LEFT JOIN {{ ref('ref_t24_ocbh_ft_outward_purpose') }} ref_purpose
    ON s.purpose_code = ref_purpose.ref_code

LEFT JOIN {{ ref('ref_t24_bc_sort_code') }} ref_bsc_3
    ON CASE 
           WHEN s.transaction_type IN ('BIIB','ITVC') THEN s.t_o_pci_code 
           ELSE NULL 
       END = ref_bsc_3.ref_code