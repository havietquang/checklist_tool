-- Source: way4.ows_item | Target: hub_item, sat_item_information, sat_item_balance_rate
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_ows_item; CREATE TEMPORARY TABLE tmp_ows_item AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS item_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(n_of_cycle          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cycle_template      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_tariff     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(account_number      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gl_number           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acc_cycle_code      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(service_class       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(currency            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cycle_id            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cycle_date_to       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cycle_event         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_from           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_to             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(due_date            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(due_status          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(account__oid        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(templ_approved_id   AS string))), ''), 256) AS hd_item_information,
    sha2(COALESCE(UPPER(TRIM(CAST(begin_balance     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cycle_balance     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(item_total        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(fee_total         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_factor   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_rate     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(interest_fee_rate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(number_of_docs    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(partition_key     AS string))), ''), 256) AS hd_item_balance_rate,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    n_of_cycle, cycle_template, interest_tariff, account_number, gl_number, acc_cycle_code,
    service_class, currency, cycle_id, cycle_date_to, cycle_event, date_from, date_to,
    due_date, due_status, account__oid, templ_approved_id,
    begin_balance, cycle_balance, item_total, fee_total, interest_factor, interest_rate,
    interest_fee_rate, number_of_docs, partition_key
FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_item')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- HUB: hub_item
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_item')
(item_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_ows_item QUALIFY ROW_NUMBER() OVER (PARTITION BY item_hashkey ORDER BY data_date) = 1)
SELECT d.item_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 'way4__ows_item'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_item') t
    ON t.item_hashkey = d.item_hashkey;

-- SAT: sat_item_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_item_information')
(
 item_hashkey, hashdiff, source_event_date, load_timestamp, record_source, acc_cycle_code,
 account__oid, account_number, currency, cycle_date_to, cycle_event, cycle_id, cycle_template,
 date_from, date_to, due_date, due_status, gl_number, interest_tariff, n_of_cycle, service_class,
 templ_approved_id
)
WITH deduped AS (SELECT * FROM tmp_ows_item QUALIFY ROW_NUMBER() OVER (PARTITION BY item_hashkey, hd_item_information ORDER BY data_date) = 1)
SELECT d.item_hashkey, d.hd_item_information, d.source_event_date, current_timestamp(),
       'way4__ows_item', d.acc_cycle_code, d.account__oid, d.account_number, d.currency,
       d.cycle_date_to, d.cycle_event, d.cycle_id, d.cycle_template, d.date_from, d.date_to,
       d.due_date, d.due_status, d.gl_number, d.interest_tariff, d.n_of_cycle, d.service_class,
       d.templ_approved_id
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_item_information') t
    ON t.item_hashkey = d.item_hashkey AND t.hashdiff = d.hd_item_information;

-- SAT: sat_item_balance_rate
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_item_balance_rate')
(
 item_hashkey, hashdiff, source_event_date, load_timestamp, record_source, begin_balance,
 cycle_balance, fee_total, interest_factor, interest_fee_rate, interest_rate, item_total,
 number_of_docs, partition_key
)
WITH deduped AS (SELECT * FROM tmp_ows_item QUALIFY ROW_NUMBER() OVER (PARTITION BY item_hashkey, hd_item_balance_rate ORDER BY data_date) = 1)
SELECT d.item_hashkey, d.hd_item_balance_rate, d.source_event_date, current_timestamp(),
       'way4__ows_item', d.begin_balance, d.cycle_balance, d.fee_total, d.interest_factor,
       d.interest_fee_rate, d.interest_rate, d.item_total, d.number_of_docs, d.partition_key
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_item_balance_rate') t
    ON t.item_hashkey = d.item_hashkey AND t.hashdiff = d.hd_item_balance_rate;

-- LINK link_item_account_w4
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_item_account_w4')
(
 link_item_account_w4_hashkey, source_event_date, load_timestamp, record_source,
 account_w4_hashkey, item_hashkey
)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(account__oid AS string))), ''), 256) AS link_item_account_w4_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS item_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(account__oid AS string))), ''), 256) AS account_w4_hashkey,
        source_event_date
    FROM tmp_ows_item
    WHERE account__oid IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id, account__oid ORDER BY data_date) = 1
)
SELECT d.link_item_account_w4_hashkey, d.source_event_date, current_timestamp(), 'way4__ows_item',
       d.account_w4_hashkey, d.item_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_item_account_w4') t
    ON t.link_item_account_w4_hashkey = d.link_item_account_w4_hashkey;

-- LINK link_item_templ_approved
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_item_templ_approved')
(
 link_item_templ_approved_hashkey, source_event_date, load_timestamp, record_source, item_hashkey,
 templ_approved_hashkey
)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(templ_approved_id AS string))), ''), 256) AS link_item_templ_approved_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS item_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(templ_approved_id AS string))), ''), 256) AS templ_approved_hashkey,
        source_event_date
    FROM tmp_ows_item
    WHERE templ_approved_id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id, templ_approved_id ORDER BY data_date) = 1
)
SELECT d.link_item_templ_approved_hashkey, d.source_event_date, current_timestamp(),
       'way4__ows_item', d.item_hashkey, d.templ_approved_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_item_templ_approved') t
    ON t.link_item_templ_approved_hashkey = d.link_item_templ_approved_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_ows_item;
