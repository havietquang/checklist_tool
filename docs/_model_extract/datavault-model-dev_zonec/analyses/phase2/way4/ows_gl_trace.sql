-- Source: way4.ows_gl_trace | Target: hub_gl_trace, sat_gl_trace_credit, sat_gl_trace_debit, sat_gl_trace_information
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_ows_gl_trace; CREATE TEMPORARY TABLE tmp_ows_gl_trace AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS gl_trace_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(cr_account        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cr_account_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cr_main_account   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cr_service        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cr_tariff         AS string))), ''), 256) AS hd_gl_trace_credit,
    sha2(COALESCE(UPPER(TRIM(CAST(dr_account        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dr_account_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dr_main_account   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dr_service        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dr_tariff         AS string))), ''), 256) AS hd_gl_trace_debit,
    sha2(COALESCE(UPPER(TRIM(CAST(curr               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(amount             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trans_role         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(entry_role         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gl_doc_id          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(order_date         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(description        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(db_date            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(partition_key      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gl_transfer__id    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(m_transaction__id  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cr_main_entry      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dr_main_entry      AS string))), ''), 256) AS hd_gl_trace_information,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    cr_account, cr_account_number, cr_main_account, cr_service, cr_tariff,
    dr_account, dr_account_number, dr_main_account, dr_service, dr_tariff,
    curr, amount, trans_role, entry_role, gl_doc_id, order_date, description, db_date,
    partition_key, gl_transfer__id, m_transaction__id, cr_main_entry, dr_main_entry
FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_gl_trace')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- HUB: hub_gl_trace
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_gl_trace')
(gl_trace_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_ows_gl_trace QUALIFY ROW_NUMBER() OVER (PARTITION BY gl_trace_hashkey ORDER BY data_date) = 1)
SELECT d.gl_trace_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 'way4__ows_gl_trace'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_gl_trace') t
    ON t.gl_trace_hashkey = d.gl_trace_hashkey;

-- SAT: sat_gl_trace_credit
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_gl_trace_credit')
(gl_trace_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 cr_account, cr_account_number, cr_main_account, cr_service, cr_tariff)
WITH deduped AS (SELECT * FROM tmp_ows_gl_trace QUALIFY ROW_NUMBER() OVER (PARTITION BY gl_trace_hashkey, hd_gl_trace_credit ORDER BY data_date) = 1)
SELECT d.gl_trace_hashkey, d.hd_gl_trace_credit, d.source_event_date, current_timestamp(), 'way4__ows_gl_trace',
       d.cr_account, d.cr_account_number, d.cr_main_account, d.cr_service, d.cr_tariff
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_gl_trace_credit') t
    ON t.gl_trace_hashkey = d.gl_trace_hashkey AND t.hashdiff = d.hd_gl_trace_credit;

-- SAT: sat_gl_trace_debit
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_gl_trace_debit')
(gl_trace_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 dr_account, dr_account_number, dr_main_account, dr_service, dr_tariff)
WITH deduped AS (SELECT * FROM tmp_ows_gl_trace QUALIFY ROW_NUMBER() OVER (PARTITION BY gl_trace_hashkey, hd_gl_trace_debit ORDER BY data_date) = 1)
SELECT d.gl_trace_hashkey, d.hd_gl_trace_debit, d.source_event_date, current_timestamp(), 'way4__ows_gl_trace',
       d.dr_account, d.dr_account_number, d.dr_main_account, d.dr_service, d.dr_tariff
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_gl_trace_debit') t
    ON t.gl_trace_hashkey = d.gl_trace_hashkey AND t.hashdiff = d.hd_gl_trace_debit;

-- SAT: sat_gl_trace_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_gl_trace_information')
(
 gl_trace_hashkey, hashdiff, source_event_date, load_timestamp, record_source, amount,
 cr_main_entry, curr, db_date, description, dr_main_entry, entry_role, gl_doc_id, gl_transfer__id,
 m_transaction__id, order_date, partition_key, trans_role
)
WITH deduped AS (SELECT * FROM tmp_ows_gl_trace QUALIFY ROW_NUMBER() OVER (PARTITION BY gl_trace_hashkey, hd_gl_trace_information ORDER BY data_date) = 1)
SELECT d.gl_trace_hashkey, d.hd_gl_trace_information, d.source_event_date, current_timestamp(),
       'way4__ows_gl_trace', d.amount, d.cr_main_entry, d.curr, d.db_date, d.description,
       d.dr_main_entry, d.entry_role, d.gl_doc_id, d.gl_transfer__id, d.m_transaction__id,
       d.order_date, d.partition_key, d.trans_role
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_gl_trace_information') t
    ON t.gl_trace_hashkey = d.gl_trace_hashkey AND t.hashdiff = d.hd_gl_trace_information;

-- LINK link_gl_trace_credit_entry
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_gl_trace_credit_entry')
(
 link_gl_trace_credit_entry_hashkey, source_event_date, load_timestamp, record_source,
 entry_hashkey, gl_trace_hashkey
)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(cr_main_entry AS string))), ''), 256) AS link_gl_trace_credit_entry_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS gl_trace_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(cr_main_entry AS string))), ''), 256) AS entry_hashkey,
        source_event_date
    FROM tmp_ows_gl_trace
    WHERE cr_main_entry IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id, cr_main_entry ORDER BY data_date) = 1
)
SELECT d.link_gl_trace_credit_entry_hashkey, d.source_event_date, current_timestamp(),
       'way4__ows_gl_trace', d.entry_hashkey, d.gl_trace_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_gl_trace_credit_entry') t
    ON t.link_gl_trace_credit_entry_hashkey = d.link_gl_trace_credit_entry_hashkey;

-- LINK link_gl_trace_debit_entry
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_gl_trace_debit_entry')
(
 link_gl_trace_debit_entry_hashkey, source_event_date, load_timestamp, record_source,
 entry_hashkey, gl_trace_hashkey
)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(dr_main_entry AS string))), ''), 256) AS link_gl_trace_debit_entry_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS gl_trace_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(dr_main_entry AS string))), ''), 256) AS entry_hashkey,
        source_event_date
    FROM tmp_ows_gl_trace
    WHERE dr_main_entry IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id, dr_main_entry ORDER BY data_date) = 1
)
SELECT d.link_gl_trace_debit_entry_hashkey, d.source_event_date, current_timestamp(),
       'way4__ows_gl_trace', d.entry_hashkey, d.gl_trace_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_gl_trace_debit_entry') t
    ON t.link_gl_trace_debit_entry_hashkey = d.link_gl_trace_debit_entry_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_ows_gl_trace;
