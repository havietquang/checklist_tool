-- Source: .t24.t24_standing_order
-- Target: :catalog_cleaned.raw_vault
--   hub_standing_order, sts_hub_standing_order, sat_standing_order, sat_standing_order_dynamic
--   link_standing_order_credit_customer, link_standing_order_debit_customer
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_standing_order; CREATE TEMPORARY TABLE tmp_t24_standing_order AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS standing_order_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_currency AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_payment_details AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pay_method AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_current_amount_bal AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ordering_cust AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_debit_customer AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_credit_customer AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cpty_acct_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acct_officer AS string))), ''), 256) AS hd_standing_order,
    sha2(COALESCE(UPPER(TRIM(CAST(t_current_frequency AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_curr_freq_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_current_end_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_last_run_date AS string))), ''), 256) AS hd_standing_order_dynamic,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_credit_customer AS string))), ''), 256) AS link_so_credit_cust_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_debit_customer AS string))), ''), 256) AS link_so_debit_cust_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_credit_customer AS string))), ''), 256) AS credit_customer_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_debit_customer AS string))), ''), 256) AS debit_customer_hashkey,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_currency, t_payment_details, t_type, t_pay_method, t_current_amount_bal, t_ordering_cust,
    t_debit_customer, t_credit_customer, t_cpty_acct_no, t_co_code, t_acct_officer,
    t_current_frequency, t_curr_freq_date, t_current_end_date, t_inputter, t_authoriser, t_last_run_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_standing_order')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_standing_order] Insert business keys not yet in hub (ANTI JOIN on hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_standing_order')
(standing_order_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_standing_order QUALIFY ROW_NUMBER() OVER (PARTITION BY standing_order_hashkey ORDER BY data_date) = 1)
SELECT d.standing_order_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 't24__t24_standing_order'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_standing_order') t
    ON t.standing_order_hashkey = d.standing_order_hashkey;

-- [sts_hub_standing_order] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_standing_order')
(standing_order_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_standing_order
),
present_per_date AS (
    SELECT DISTINCT standing_order_hashkey, source_event_date FROM tmp_t24_standing_order
),
full_timeline AS (
    SELECT DISTINCT h.standing_order_hashkey, d.source_event_date,
           CASE WHEN p.standing_order_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_standing_order') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.standing_order_hashkey = h.standing_order_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT standing_order_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY standing_order_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT standing_order_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_standing_order')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_standing_order)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY standing_order_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.standing_order_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.standing_order_hashkey = t.standing_order_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.standing_order_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.standing_order_hashkey = t.standing_order_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.standing_order_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_standing_order') t
    ON t.standing_order_hashkey = sc.standing_order_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_standing_order] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_standing_order')
(standing_order_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_currency, t_payment_details, t_type, t_pay_method, t_current_amount_bal, t_ordering_cust,
 t_debit_customer, t_credit_customer, t_cpty_acct_no, t_co_code, t_acct_officer)
WITH last_known AS (
    SELECT standing_order_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_standing_order')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY standing_order_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_standing_order) OVER (PARTITION BY s.standing_order_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_standing_order s
    LEFT JOIN last_known lk ON lk.standing_order_hashkey = s.standing_order_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_standing_order != prev_hashdiff)
SELECT d.standing_order_hashkey, d.hd_standing_order, d.source_event_date, current_timestamp(), 't24__t24_standing_order',
       d.t_currency, d.t_payment_details, d.t_type, d.t_pay_method, d.t_current_amount_bal, d.t_ordering_cust,
       d.t_debit_customer, d.t_credit_customer, d.t_cpty_acct_no, d.t_co_code, d.t_acct_officer
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_standing_order') t ON t.standing_order_hashkey = d.standing_order_hashkey AND t.source_event_date = d.source_event_date;

-- [sat_standing_order_dynamic] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_standing_order_dynamic')
(standing_order_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_current_frequency, t_curr_freq_date, t_current_end_date, t_inputter, t_authoriser, t_last_run_date)
WITH last_known AS (
    SELECT standing_order_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_standing_order_dynamic')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY standing_order_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_standing_order_dynamic) OVER (PARTITION BY s.standing_order_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_standing_order s
    LEFT JOIN last_known lk ON lk.standing_order_hashkey = s.standing_order_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_standing_order_dynamic != prev_hashdiff)
SELECT d.standing_order_hashkey, d.hd_standing_order_dynamic, d.source_event_date, current_timestamp(), 't24__t24_standing_order',
       d.t_current_frequency, d.t_curr_freq_date, d.t_current_end_date, d.t_inputter, d.t_authoriser, d.t_last_run_date
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_standing_order_dynamic') t ON t.standing_order_hashkey = d.standing_order_hashkey AND t.source_event_date = d.source_event_date;

-- [link_standing_order_credit_customer] Insert new relationships (ANTI JOIN on link hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_standing_order_credit_customer')
(link_standing_order_credit_customer_hashkey, standing_order_hashkey, customer_hashkey, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_standing_order WHERE t_credit_customer IS NOT NULL QUALIFY ROW_NUMBER() OVER (PARTITION BY link_so_credit_cust_hashkey ORDER BY data_date) = 1)
SELECT d.link_so_credit_cust_hashkey, d.standing_order_hashkey, d.credit_customer_hashkey, d.source_event_date, current_timestamp(), 't24__t24_standing_order'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_standing_order_credit_customer') t
    ON t.link_standing_order_credit_customer_hashkey = d.link_so_credit_cust_hashkey;

-- [link_standing_order_debit_customer] Insert new relationships (ANTI JOIN on link hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_standing_order_debit_customer')
(link_standing_order_debit_customer_hashkey, standing_order_hashkey, customer_hashkey, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_standing_order WHERE t_debit_customer IS NOT NULL QUALIFY ROW_NUMBER() OVER (PARTITION BY link_so_debit_cust_hashkey ORDER BY data_date) = 1)
SELECT d.link_so_debit_cust_hashkey, d.standing_order_hashkey, d.debit_customer_hashkey, d.source_event_date, current_timestamp(), 't24__t24_standing_order'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_standing_order_debit_customer') t
    ON t.link_standing_order_debit_customer_hashkey = d.link_so_debit_cust_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_standing_order;
