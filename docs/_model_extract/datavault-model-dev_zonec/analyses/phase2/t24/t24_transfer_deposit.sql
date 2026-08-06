-- Source: .t24.t24_transfer_deposit
-- Target: :catalog_cleaned.raw_vault
--   hub_transfer_deposit, sts_hub_transfer_deposit, sat_transfer_deposit
--   link_transfer_deposit_az_account
--   link_transfer_deposit_customer (+ effsat_link_transfer_deposit_customer)
--   link_transfer_deposit_acct_officer (+ effsat_link_transfer_deposit_acct_officer)
--   hub_deposits (business_key = az_number — priority 2 addition)
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_transfer_deposit; CREATE TEMPORARY TABLE tmp_t24_transfer_deposit AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS transfer_deposit_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(az_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cif_old AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cif_new AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(produc_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(term AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(principal AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(mobile_new AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(legal_id_new AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_transfer AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(transfer_time_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nominated_ac AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rm_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(opening_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rm_cif AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rm_ac AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(record_status AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(inputter AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_time AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(authoriser AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(co_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(name_old AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(name_new AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rm_cif_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rm_ac_name AS string))), ''), 256) AS hd_transfer_deposit,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(az_number AS string))), ''), 256) AS link_td_az_account_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cif_new AS string))), ''), 256) AS link_td_customer_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rm_code AS string))), ''), 256) AS link_td_acct_officer_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(az_number AS string))), ''), 256) AS deposit_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(cif_new AS string))), ''), 256) AS customer_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(rm_code AS string))), ''), 256) AS dept_acct_officer_hashkey,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    az_number, cif_old, cif_new, produc_code, term, principal, mobile_new, legal_id_new,
    date_transfer, transfer_time_no, nominated_ac, rm_code, opening_date, rm_cif, rm_ac,
    record_status, inputter, date_time, authoriser, co_code, name_old, name_new, rm_cif_name, rm_ac_name
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_transfer_deposit')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_transfer_deposit] Insert business keys not yet in hub (ANTI JOIN on hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_transfer_deposit')
(transfer_deposit_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_transfer_deposit QUALIFY ROW_NUMBER() OVER (PARTITION BY transfer_deposit_hashkey ORDER BY data_date) = 1)
SELECT d.transfer_deposit_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 't24__t24_transfer_deposit'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_transfer_deposit') t
    ON t.transfer_deposit_hashkey = d.transfer_deposit_hashkey;

-- [hub_deposits] Insert business keys not yet in hub (priority 2: az_number from t24_transfer_deposit)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_deposits')
(deposit_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_transfer_deposit WHERE az_number IS NOT NULL QUALIFY ROW_NUMBER() OVER (PARTITION BY deposit_hashkey ORDER BY data_date) = 1)
SELECT d.deposit_hashkey, TRIM(CAST(d.az_number AS STRING)), d.source_event_date, current_timestamp(), 't24__t24_transfer_deposit'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_deposits') t
    ON t.deposit_hashkey = d.deposit_hashkey;

-- [sts_hub_transfer_deposit] Insert status changes: D (first absence streak) and I (reinsert after D)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_transfer_deposit')
(transfer_deposit_hashkey, source_event_date, cdc_status)
WITH dates_in_range AS (
    SELECT DISTINCT source_event_date FROM tmp_t24_transfer_deposit
),
present_per_date AS (
    SELECT DISTINCT transfer_deposit_hashkey, source_event_date FROM tmp_t24_transfer_deposit
),
full_timeline AS (
    SELECT DISTINCT h.transfer_deposit_hashkey, d.source_event_date,
           CASE WHEN p.transfer_deposit_hashkey IS NOT NULL THEN 'I' ELSE 'D' END AS status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_transfer_deposit') h
    CROSS JOIN dates_in_range d
    LEFT JOIN present_per_date p ON p.transfer_deposit_hashkey = h.transfer_deposit_hashkey AND p.source_event_date = d.source_event_date
    WHERE h.source_event_date <= d.source_event_date
),
timeline_with_lag AS (
    SELECT transfer_deposit_hashkey, source_event_date, status,
           LAG(status) OVER (PARTITION BY transfer_deposit_hashkey ORDER BY source_event_date) AS prev_status
    FROM full_timeline
),
pre_batch_status AS (
    SELECT transfer_deposit_hashkey, cdc_status
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_transfer_deposit')
    WHERE source_event_date < (SELECT MIN(source_event_date) FROM tmp_t24_transfer_deposit)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY transfer_deposit_hashkey ORDER BY source_event_date DESC) = 1
),
status_changes AS (
    -- D: first day key is absent after being present (I->D transition)
    SELECT t.transfer_deposit_hashkey, t.source_event_date, 'D' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.transfer_deposit_hashkey = t.transfer_deposit_hashkey
    WHERE t.status = 'D'
      AND (t.prev_status = 'I'
           OR (t.prev_status IS NULL AND COALESCE(ps.cdc_status, 'I') != 'D'))
    UNION ALL
    -- I: key reappears in source after being deleted (D->I transition)
    SELECT t.transfer_deposit_hashkey, t.source_event_date, 'I' AS cdc_status
    FROM timeline_with_lag t
    LEFT JOIN pre_batch_status ps ON ps.transfer_deposit_hashkey = t.transfer_deposit_hashkey
    WHERE t.status = 'I'
      AND (t.prev_status = 'D'
           OR (t.prev_status IS NULL AND ps.cdc_status = 'D'))
)
SELECT sc.transfer_deposit_hashkey, sc.source_event_date, sc.cdc_status
FROM status_changes sc
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sts_hub_transfer_deposit') t
    ON t.transfer_deposit_hashkey = sc.transfer_deposit_hashkey AND t.source_event_date = sc.source_event_date AND t.cdc_status = sc.cdc_status;

-- [sat_transfer_deposit] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_transfer_deposit')
(transfer_deposit_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 az_number, cif_old, cif_new, produc_code, term, principal, mobile_new, legal_id_new,
 date_transfer, transfer_time_no, nominated_ac, rm_code, opening_date, rm_cif, rm_ac,
 record_status, inputter, date_time, authoriser, co_code, name_old, name_new, rm_cif_name, rm_ac_name)
WITH last_known AS (
    SELECT transfer_deposit_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_transfer_deposit')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY transfer_deposit_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_transfer_deposit) OVER (PARTITION BY s.transfer_deposit_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_transfer_deposit s
    LEFT JOIN last_known lk ON lk.transfer_deposit_hashkey = s.transfer_deposit_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_transfer_deposit != prev_hashdiff)
SELECT d.transfer_deposit_hashkey, d.hd_transfer_deposit, d.source_event_date, current_timestamp(), 't24__t24_transfer_deposit',
       d.az_number, d.cif_old, d.cif_new, d.produc_code, d.term, d.principal, d.mobile_new, d.legal_id_new,
       d.date_transfer, d.transfer_time_no, d.nominated_ac, d.rm_code, d.opening_date, d.rm_cif, d.rm_ac,
       d.record_status, d.inputter, d.date_time, d.authoriser, d.co_code, d.name_old, d.name_new, d.rm_cif_name, d.rm_ac_name
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_transfer_deposit') t ON t.transfer_deposit_hashkey = d.transfer_deposit_hashkey AND t.source_event_date = d.source_event_date;

-- [link_transfer_deposit_az_account] Insert new relationships (ANTI JOIN on link hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_transfer_deposit_az_account')
(link_transfer_deposit_az_account_hashkey, transfer_deposit_hashkey, deposit_hashkey, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_transfer_deposit WHERE az_number IS NOT NULL QUALIFY ROW_NUMBER() OVER (PARTITION BY link_td_az_account_hashkey ORDER BY data_date) = 1)
SELECT d.link_td_az_account_hashkey, d.transfer_deposit_hashkey, d.deposit_hashkey, d.source_event_date, current_timestamp(), 't24__t24_transfer_deposit'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_transfer_deposit_az_account') t
    ON t.link_transfer_deposit_az_account_hashkey = d.link_td_az_account_hashkey;

-- [link_transfer_deposit_customer] Insert new relationships (ANTI JOIN on link hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_transfer_deposit_customer')
(link_transfer_deposit_customer_hashkey, transfer_deposit_hashkey, customer_hashkey, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_transfer_deposit WHERE cif_new IS NOT NULL QUALIFY ROW_NUMBER() OVER (PARTITION BY link_td_customer_hashkey ORDER BY data_date) = 1)
SELECT d.link_td_customer_hashkey, d.transfer_deposit_hashkey, d.customer_hashkey, d.source_event_date, current_timestamp(), 't24__t24_transfer_deposit'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_transfer_deposit_customer') t
    ON t.link_transfer_deposit_customer_hashkey = d.link_td_customer_hashkey;

-- [effsat_link_transfer_deposit_customer] Insert active records for links present in source
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.effsat_link_transfer_deposit_customer')
(link_transfer_deposit_customer_hashkey, source_event_date, record_source, load_timestamp, active_flag)
SELECT DISTINCT d.link_td_customer_hashkey, d.source_event_date, 't24__t24_transfer_deposit', current_timestamp(), 1
FROM tmp_t24_transfer_deposit d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.effsat_link_transfer_deposit_customer') t
    ON t.link_transfer_deposit_customer_hashkey = d.link_td_customer_hashkey AND t.source_event_date = d.source_event_date AND t.active_flag = 1
WHERE d.cif_new IS NOT NULL;

-- [link_transfer_deposit_acct_officer] Insert new relationships (ANTI JOIN on link hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_transfer_deposit_acct_officer')
(link_transfer_deposit_acct_officer_hashkey, transfer_deposit_hashkey, dept_acct_officer_hashkey, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_t24_transfer_deposit WHERE rm_code IS NOT NULL QUALIFY ROW_NUMBER() OVER (PARTITION BY link_td_acct_officer_hashkey ORDER BY data_date) = 1)
SELECT d.link_td_acct_officer_hashkey, d.transfer_deposit_hashkey, d.dept_acct_officer_hashkey, d.source_event_date, current_timestamp(), 't24__t24_transfer_deposit'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_transfer_deposit_acct_officer') t
    ON t.link_transfer_deposit_acct_officer_hashkey = d.link_td_acct_officer_hashkey;

-- [effsat_link_transfer_deposit_acct_officer] Insert active records for links present in source
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.effsat_link_transfer_deposit_acct_officer')
(link_transfer_deposit_acct_officer_hashkey, source_event_date, record_source, load_timestamp, active_flag)
SELECT DISTINCT d.link_td_acct_officer_hashkey, d.source_event_date, 't24__t24_transfer_deposit', current_timestamp(), 1
FROM tmp_t24_transfer_deposit d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.effsat_link_transfer_deposit_acct_officer') t
    ON t.link_transfer_deposit_acct_officer_hashkey = d.link_td_acct_officer_hashkey AND t.source_event_date = d.source_event_date AND t.active_flag = 1
WHERE d.rm_code IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_transfer_deposit;
