-- Source: way4.ows_account | Target: hub_account_w4, sat_account_w4_information, sat_account_w4_balance
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_ows_account; CREATE TEMPORARY TABLE tmp_ows_account AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS account_w4_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(code                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(curr                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acat                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(due_type              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(account_type          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(account_name          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(account_number        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gl_number             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_templ__id         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(routing_idt           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_am_available       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(apply_dt              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(local_version         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(remote_version        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_rate         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_fee_rate     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ageing_priority       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(main_account          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(alter_account         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(top_account           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(due_account           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(alter_due_account     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(low_lim_account       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(upp_lim_account       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_account      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acnt_contract__oid    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(total_blocked         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(own_blocked           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(charge_for_open       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(payment_priority      AS string))), ''), 256) AS hd_account_w4_information,
    sha2(COALESCE(UPPER(TRIM(CAST(begin_balance     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(current_balance   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(low_lim_amount    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(upp_lim_amount    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(on_date_balance   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(on_date           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cycle_date_from   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cycle_date_to     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(n_of_cycle        AS string))), ''), 256) AS hd_account_w4_balance,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    code, curr, acat, due_type, account_type, account_name, account_number, gl_number,
    acc_templ__id, routing_idt, is_am_available, apply_dt, local_version, remote_version,
    interest_rate, interest_fee_rate, ageing_priority, main_account, alter_account, top_account,
    due_account, alter_due_account, low_lim_account, upp_lim_account, interest_account,
    acnt_contract__oid, total_blocked, own_blocked, charge_for_open, payment_priority,
    begin_balance, current_balance, low_lim_amount, upp_lim_amount, on_date_balance, on_date,
    cycle_date_from, cycle_date_to, n_of_cycle
FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_account')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- HUB: hub_account_w4
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_account_w4')
(account_w4_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_ows_account QUALIFY ROW_NUMBER() OVER (PARTITION BY account_w4_hashkey ORDER BY data_date) = 1)
SELECT d.account_w4_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 'way4__ows_account'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_account_w4') t
    ON t.account_w4_hashkey = d.account_w4_hashkey;

-- SAT: sat_account_w4_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_account_w4_information')
(
 account_w4_hashkey, hashdiff, source_event_date, load_timestamp, record_source, acat,
 acc_templ__id, account_name, account_number, account_type, acnt_contract__oid, ageing_priority,
 alter_account, alter_due_account, apply_dt, charge_for_open, code, curr, due_account, due_type,
 gl_number, interest_account, interest_fee_rate, interest_rate, is_am_available, local_version,
 low_lim_account, main_account, own_blocked, payment_priority, remote_version, routing_idt,
 top_account, total_blocked, upp_lim_account
)
WITH deduped AS (SELECT * FROM tmp_ows_account QUALIFY ROW_NUMBER() OVER (PARTITION BY account_w4_hashkey, hd_account_w4_information ORDER BY data_date) = 1)
SELECT d.account_w4_hashkey, d.hd_account_w4_information, d.source_event_date,
       current_timestamp(), 'way4__ows_account', d.acat, d.acc_templ__id, d.account_name,
       d.account_number, d.account_type, d.acnt_contract__oid, d.ageing_priority, d.alter_account,
       d.alter_due_account, d.apply_dt, d.charge_for_open, d.code, d.curr, d.due_account,
       d.due_type, d.gl_number, d.interest_account, d.interest_fee_rate, d.interest_rate,
       d.is_am_available, d.local_version, d.low_lim_account, d.main_account, d.own_blocked,
       d.payment_priority, d.remote_version, d.routing_idt, d.top_account, d.total_blocked,
       d.upp_lim_account
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_account_w4_information') t
    ON t.account_w4_hashkey = d.account_w4_hashkey AND t.hashdiff = d.hd_account_w4_information;

-- SAT: sat_account_w4_balance
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_account_w4_balance')
(
 account_w4_hashkey, hashdiff, source_event_date, load_timestamp, record_source, begin_balance,
 current_balance, cycle_date_from, cycle_date_to, low_lim_amount, n_of_cycle, on_date,
 on_date_balance, upp_lim_amount
)
WITH deduped AS (SELECT * FROM tmp_ows_account QUALIFY ROW_NUMBER() OVER (PARTITION BY account_w4_hashkey, hd_account_w4_balance ORDER BY data_date) = 1)
SELECT d.account_w4_hashkey, d.hd_account_w4_balance, d.source_event_date, current_timestamp(),
       'way4__ows_account', d.begin_balance, d.current_balance, d.cycle_date_from,
       d.cycle_date_to, d.low_lim_amount, d.n_of_cycle, d.on_date, d.on_date_balance,
       d.upp_lim_amount
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_account_w4_balance') t
    ON t.account_w4_hashkey = d.account_w4_hashkey AND t.hashdiff = d.hd_account_w4_balance;

-- LINK link_account_w4_acc_templ
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_account_w4_acc_templ')
(
 link_account_w4_acc_templ_hashkey, source_event_date, load_timestamp, record_source,
 acc_templ_hashkey, account_w4_hashkey
)
WITH keyed AS (
    SELECT
        t.id, t.acc_templ__id, t.source_event_date,
        sha2(COALESCE(UPPER(TRIM(CAST(t.acc_templ__id AS string))), ''), 256) AS acc_templ_hashkey
    FROM tmp_ows_account t
    WHERE t.acc_templ__id IS NOT NULL
),
src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(k.id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(k.acc_templ__id AS string))), ''), 256) AS link_account_w4_acc_templ_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(k.id AS string))), ''), 256) AS account_w4_hashkey,
        p.acc_templ_hashkey,
        MIN(k.source_event_date) AS source_event_date
    FROM keyed k
    JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_acc_templ') p
      ON k.acc_templ_hashkey = p.acc_templ_hashkey
    GROUP BY 1, 2, 3
)
SELECT d.link_account_w4_acc_templ_hashkey, d.source_event_date, current_timestamp(),
       'way4__ows_account', d.acc_templ_hashkey, d.account_w4_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_account_w4_acc_templ') t
    ON t.link_account_w4_acc_templ_hashkey = d.link_account_w4_acc_templ_hashkey;

-- LINK link_account_w4_acnt_contract
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_account_w4_acnt_contract')
(
 link_account_w4_acnt_contract_hashkey, source_event_date, load_timestamp, record_source,
 account_w4_hashkey, acnt_contract_hashkey
)
WITH keyed AS (
    SELECT
        t.id, t.acnt_contract__oid, t.source_event_date,
        sha2(COALESCE(UPPER(TRIM(CAST(t.acnt_contract__oid AS string))), ''), 256) AS acnt_contract_hashkey
    FROM tmp_ows_account t
    WHERE t.acnt_contract__oid IS NOT NULL
),
src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(k.id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(k.acnt_contract__oid AS string))), ''), 256) AS link_account_w4_acnt_contract_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(k.id AS string))), ''), 256) AS account_w4_hashkey,
        p.acnt_contract_hashkey,
        MIN(k.source_event_date) AS source_event_date
    FROM keyed k
    JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_acnt_contract') p
      ON k.acnt_contract_hashkey = p.acnt_contract_hashkey
    GROUP BY 1, 2, 3
)
SELECT d.link_account_w4_acnt_contract_hashkey, d.source_event_date, current_timestamp(),
       'way4__ows_account', d.account_w4_hashkey, d.acnt_contract_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_account_w4_acnt_contract') t
    ON t.link_account_w4_acnt_contract_hashkey = d.link_account_w4_acnt_contract_hashkey;

-- STS HUB: sts_hub_account_w4 (CDC delete/reinsert tren snapshot data_date trong [start,end]; doc tu tmp_ows_account)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_w4')
(account_w4_hashkey, source_event_date, cdc_status)
WITH staging AS (
    SELECT DISTINCT account_w4_hashkey, data_date FROM tmp_ows_account
),
days AS (SELECT DISTINCT data_date FROM staging),
key_first AS (
    SELECT account_w4_hashkey, MIN(data_date) AS first_day FROM staging GROUP BY account_w4_hashkey
),
grid AS (
    SELECT k.account_w4_hashkey, d.data_date
    FROM key_first k JOIN days d ON d.data_date >= k.first_day
),
flagged AS (
    SELECT g.account_w4_hashkey, g.data_date,
           CASE WHEN s.account_w4_hashkey IS NOT NULL THEN 1 ELSE 0 END AS present
    FROM grid g
    LEFT JOIN staging s ON s.account_w4_hashkey = g.account_w4_hashkey AND s.data_date = g.data_date
),
trans AS (
    SELECT account_w4_hashkey, data_date, present,
           lag(present) OVER (PARTITION BY account_w4_hashkey ORDER BY data_date) AS prev_present
    FROM flagged
),
cdc AS (
    SELECT account_w4_hashkey, to_date(CAST(data_date AS string), 'yyyyMMdd') AS source_event_date, CAST('D' AS string) AS cdc_status
    FROM trans WHERE prev_present = 1 AND present = 0
    UNION ALL
    SELECT account_w4_hashkey, to_date(CAST(data_date AS string), 'yyyyMMdd') AS source_event_date, CAST('I' AS string) AS cdc_status
    FROM trans WHERE prev_present = 0 AND present = 1
)
SELECT d.account_w4_hashkey, d.source_event_date, d.cdc_status
FROM cdc d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_account_w4') t
    ON t.account_w4_hashkey = d.account_w4_hashkey
   AND t.source_event_date = d.source_event_date
   AND t.cdc_status = d.cdc_status;

DROP TEMPORARY TABLE IF EXISTS tmp_ows_account;
