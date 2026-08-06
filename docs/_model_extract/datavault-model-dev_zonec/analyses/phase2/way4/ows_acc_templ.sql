-- Source: way4.ows_acc_templ | Target: hub_acc_templ, sat_acc_templ_information, sat_acc_templ_gl, sat_acc_templ_interest, sat_acc_templ_limit
-- Full load init
DROP TEMPORARY TABLE IF EXISTS tmp_ows_acc_templ; CREATE TEMPORARY TABLE tmp_ows_acc_templ AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS acc_templ_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(acc_scheme__oid      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(from_acc_scheme      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(account_type__id     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(f_i                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(pcat                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acat                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(reference_only       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(code                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(curr                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(account_name         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(fx_type              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(due_type             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(due_period           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(grace_period         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(due_to_work_day      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(repayment_percent    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(min_repayment        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(min_rq_repayment     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ageing_tariff        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_am_available      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(balance_type         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(group_code           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(charge_for_open      AS string))), ''), 256) AS hd_acc_templ_information,
    sha2(COALESCE(UPPER(TRIM(CAST(gl_credit            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gl_debit             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gl_turnover          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gl_type              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gl_number            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hd_gl_number         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gl_tariff            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(use_gl               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(account_numeration   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_number_counter   AS string))), ''), 256) AS hd_acc_templ_gl,
    sha2(COALESCE(UPPER(TRIM(CAST(interest_scheme      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_algorithm   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(calc_when_credit     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_delay       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_rate        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_fee         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_acc_templ   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_contract    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(int_accrual_acc      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(int_rev_exp_acc      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(int_fee_account      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_fee_type    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(fee_rate_regime      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_tariff      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(last_int_accrual     AS string))), ''), 256) AS hd_acc_templ_interest,
    sha2(COALESCE(UPPER(TRIM(CAST(due_acc_templ        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(alter_due_templ      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(event_type           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(upp_lim_acc_templ    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(low_lim_acc_templ    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(upp_lim_amount       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(low_lim_amount       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(priority             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ageing_priority      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(offbalance_xf_acc    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(suppl_cr_account     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(suppl_dr_account     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(template_details     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_ready             AS string))), ''), 256) AS hd_acc_templ_limit,
    to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
    id,
    acc_scheme__oid, from_acc_scheme, account_type__id, f_i, pcat, acat, reference_only, code, curr,
    account_name, fx_type, due_type, due_period, grace_period, due_to_work_day, repayment_percent,
    min_repayment, min_rq_repayment, ageing_tariff, is_am_available, balance_type, group_code, charge_for_open,
    gl_credit, gl_debit, gl_turnover, gl_type, gl_number, hd_gl_number, gl_tariff, use_gl,
    account_numeration, acc_number_counter,
    interest_scheme, interest_algorithm, calc_when_credit, interest_delay, interest_rate, interest_fee,
    interest_acc_templ, interest_contract, int_accrual_acc, int_rev_exp_acc, int_fee_account,
    interest_fee_type, fee_rate_regime, interest_tariff, last_int_accrual,
    due_acc_templ, alter_due_templ, event_type, upp_lim_acc_templ, low_lim_acc_templ,
    upp_lim_amount, low_lim_amount, priority, ageing_priority, offbalance_xf_acc,
    suppl_cr_account, suppl_dr_account, template_details, is_ready
FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_acc_templ')
WHERE id IS NOT NULL AND amnd_state = 'A';

-- HUB: hub_acc_templ
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_acc_templ')
(acc_templ_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_ows_acc_templ QUALIFY ROW_NUMBER() OVER (PARTITION BY acc_templ_hashkey ORDER BY 1) = 1)
SELECT d.acc_templ_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 'way4__ows_acc_templ'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_acc_templ') t
    ON t.acc_templ_hashkey = d.acc_templ_hashkey;

-- SAT: sat_acc_templ_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_acc_templ_information')
(
 acc_templ_hashkey, hashdiff, source_event_date, load_timestamp, record_source, acat,
 acc_scheme__oid, account_name, account_type__id, ageing_tariff, balance_type, charge_for_open,
 code, curr, due_period, due_to_work_day, due_type, f_i, from_acc_scheme, fx_type, grace_period,
 group_code, is_am_available, min_repayment, min_rq_repayment, pcat, reference_only,
 repayment_percent
)
WITH deduped AS (SELECT * FROM tmp_ows_acc_templ QUALIFY ROW_NUMBER() OVER (PARTITION BY acc_templ_hashkey, hd_acc_templ_information ORDER BY 1) = 1)
SELECT d.acc_templ_hashkey, d.hd_acc_templ_information, d.source_event_date, current_timestamp(),
       'way4__ows_acc_templ', d.acat, d.acc_scheme__oid, d.account_name, d.account_type__id,
       d.ageing_tariff, d.balance_type, d.charge_for_open, d.code, d.curr, d.due_period,
       d.due_to_work_day, d.due_type, d.f_i, d.from_acc_scheme, d.fx_type, d.grace_period,
       d.group_code, d.is_am_available, d.min_repayment, d.min_rq_repayment, d.pcat,
       d.reference_only, d.repayment_percent
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_acc_templ_information') t
    ON t.acc_templ_hashkey = d.acc_templ_hashkey AND t.hashdiff = d.hd_acc_templ_information;

-- SAT: sat_acc_templ_gl
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_acc_templ_gl')
(
 acc_templ_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 acc_number_counter, account_numeration, gl_credit, gl_debit, gl_number, gl_tariff, gl_turnover,
 gl_type, hd_gl_number, use_gl
)
WITH deduped AS (SELECT * FROM tmp_ows_acc_templ QUALIFY ROW_NUMBER() OVER (PARTITION BY acc_templ_hashkey, hd_acc_templ_gl ORDER BY 1) = 1)
SELECT d.acc_templ_hashkey, d.hd_acc_templ_gl, d.source_event_date, current_timestamp(),
       'way4__ows_acc_templ', d.acc_number_counter, d.account_numeration, d.gl_credit, d.gl_debit,
       d.gl_number, d.gl_tariff, d.gl_turnover, d.gl_type, d.hd_gl_number, d.use_gl
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_acc_templ_gl') t
    ON t.acc_templ_hashkey = d.acc_templ_hashkey AND t.hashdiff = d.hd_acc_templ_gl;

-- SAT: sat_acc_templ_interest
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_acc_templ_interest')
(
 acc_templ_hashkey, hashdiff, source_event_date, load_timestamp, record_source, calc_when_credit,
 fee_rate_regime, int_accrual_acc, int_fee_account, int_rev_exp_acc, interest_acc_templ,
 interest_algorithm, interest_contract, interest_delay, interest_fee, interest_fee_type,
 interest_rate, interest_scheme, interest_tariff, last_int_accrual
)
WITH deduped AS (SELECT * FROM tmp_ows_acc_templ QUALIFY ROW_NUMBER() OVER (PARTITION BY acc_templ_hashkey, hd_acc_templ_interest ORDER BY 1) = 1)
SELECT d.acc_templ_hashkey, d.hd_acc_templ_interest, d.source_event_date, current_timestamp(),
       'way4__ows_acc_templ', d.calc_when_credit, d.fee_rate_regime, d.int_accrual_acc,
       d.int_fee_account, d.int_rev_exp_acc, d.interest_acc_templ, d.interest_algorithm,
       d.interest_contract, d.interest_delay, d.interest_fee, d.interest_fee_type,
       d.interest_rate, d.interest_scheme, d.interest_tariff, d.last_int_accrual
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_acc_templ_interest') t
    ON t.acc_templ_hashkey = d.acc_templ_hashkey AND t.hashdiff = d.hd_acc_templ_interest;

-- SAT: sat_acc_templ_limit
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_acc_templ_limit')
(
 acc_templ_hashkey, hashdiff, source_event_date, load_timestamp, record_source, ageing_priority,
 alter_due_templ, due_acc_templ, event_type, is_ready, low_lim_acc_templ, low_lim_amount,
 offbalance_xf_acc, priority, suppl_cr_account, suppl_dr_account, template_details,
 upp_lim_acc_templ, upp_lim_amount
)
WITH deduped AS (SELECT * FROM tmp_ows_acc_templ QUALIFY ROW_NUMBER() OVER (PARTITION BY acc_templ_hashkey, hd_acc_templ_limit ORDER BY 1) = 1)
SELECT d.acc_templ_hashkey, d.hd_acc_templ_limit, d.source_event_date, current_timestamp(),
       'way4__ows_acc_templ', d.ageing_priority, d.alter_due_templ, d.due_acc_templ, d.event_type,
       d.is_ready, d.low_lim_acc_templ, d.low_lim_amount, d.offbalance_xf_acc, d.priority,
       d.suppl_cr_account, d.suppl_dr_account, d.template_details, d.upp_lim_acc_templ,
       d.upp_lim_amount
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_acc_templ_limit') t
    ON t.acc_templ_hashkey = d.acc_templ_hashkey AND t.hashdiff = d.hd_acc_templ_limit;

DROP TEMPORARY TABLE IF EXISTS tmp_ows_acc_templ;
