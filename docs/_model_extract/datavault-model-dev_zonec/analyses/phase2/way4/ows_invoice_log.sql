-- Source: way4.ows_invoice_log | Target: hub_invoice_log, sat_invoice_log_information, sat_invoice_log_detail
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_ows_invoice_log; CREATE TEMPORARY TABLE tmp_ows_invoice_log AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS invoice_log_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(eff_date              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rep_date              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(due_date              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(invoice_amount        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(paid_amount           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(written_off_amount    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(invoice_status        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(invoice_status_pre    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(invoice_code          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(invoice_ref_number    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(curr                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(invoice_group         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(instalment_plan       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(inst_chain_idt        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(inst_fee__id          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(contract_for          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(instalment_scheme     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(invoice_log__oid      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acnt_contract__oid    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(doc_id               AS string))), ''), 256) AS hd_invoice_log_information,
    sha2(COALESCE(UPPER(TRIM(CAST(posting_details   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(balance_code      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(creation_type     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(action_code       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(amount_type       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(debt_type         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sort_code         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(invoice_details   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(invoice_event     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(partition_key     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(creation_date     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(last_updated      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(begin_date        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(end_date          AS string))), ''), 256) AS hd_invoice_log_detail,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    eff_date, rep_date, due_date, invoice_amount, paid_amount, written_off_amount,
    invoice_status, invoice_status_pre, invoice_code, invoice_ref_number, curr, invoice_group,
    instalment_plan, inst_chain_idt, inst_fee__id, contract_for, instalment_scheme,
    invoice_log__oid, acnt_contract__oid, doc_id,
    posting_details, balance_code, creation_type, action_code, amount_type, debt_type,
    sort_code, invoice_details, invoice_event, partition_key, creation_date, last_updated,
    begin_date, end_date
FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_invoice_log')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- HUB: hub_invoice_log
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_invoice_log')
(invoice_log_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_ows_invoice_log QUALIFY ROW_NUMBER() OVER (PARTITION BY invoice_log_hashkey ORDER BY data_date) = 1)
SELECT d.invoice_log_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 'way4__ows_invoice_log'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_invoice_log') t
    ON t.invoice_log_hashkey = d.invoice_log_hashkey;

-- SAT: sat_invoice_log_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_invoice_log_information')
(
 invoice_log_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 acnt_contract__oid, contract_for, curr, doc_id, due_date, eff_date, inst_chain_idt, inst_fee__id,
 instalment_plan, instalment_scheme, invoice_amount, invoice_code, invoice_group,
 invoice_log__oid, invoice_ref_number, invoice_status, invoice_status_pre, paid_amount, rep_date,
 written_off_amount
)
WITH deduped AS (SELECT * FROM tmp_ows_invoice_log QUALIFY ROW_NUMBER() OVER (PARTITION BY invoice_log_hashkey, hd_invoice_log_information ORDER BY data_date) = 1)
SELECT d.invoice_log_hashkey, d.hd_invoice_log_information, d.source_event_date,
       current_timestamp(), 'way4__ows_invoice_log', d.acnt_contract__oid, d.contract_for, d.curr,
       d.doc_id, d.due_date, d.eff_date, d.inst_chain_idt, d.inst_fee__id, d.instalment_plan,
       d.instalment_scheme, d.invoice_amount, d.invoice_code, d.invoice_group, d.invoice_log__oid,
       d.invoice_ref_number, d.invoice_status, d.invoice_status_pre, d.paid_amount, d.rep_date,
       d.written_off_amount
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_invoice_log_information') t
    ON t.invoice_log_hashkey = d.invoice_log_hashkey AND t.hashdiff = d.hd_invoice_log_information;

-- SAT: sat_invoice_log_detail
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_invoice_log_detail')
(
 invoice_log_hashkey, hashdiff, source_event_date, load_timestamp, record_source, action_code,
 amount_type, balance_code, begin_date, creation_date, creation_type, debt_type, end_date,
 invoice_details, invoice_event, last_updated, partition_key, posting_details, sort_code
)
WITH deduped AS (SELECT * FROM tmp_ows_invoice_log QUALIFY ROW_NUMBER() OVER (PARTITION BY invoice_log_hashkey, hd_invoice_log_detail ORDER BY data_date) = 1)
SELECT d.invoice_log_hashkey, d.hd_invoice_log_detail, d.source_event_date, current_timestamp(),
       'way4__ows_invoice_log', d.action_code, d.amount_type, d.balance_code, d.begin_date,
       d.creation_date, d.creation_type, d.debt_type, d.end_date, d.invoice_details,
       d.invoice_event, d.last_updated, d.partition_key, d.posting_details, d.sort_code
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_invoice_log_detail') t
    ON t.invoice_log_hashkey = d.invoice_log_hashkey AND t.hashdiff = d.hd_invoice_log_detail;

-- LINK link_invoice_log_acnt_contract
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_invoice_log_acnt_contract')
(
 link_invoice_log_acnt_contract_hashkey, source_event_date, load_timestamp, record_source,
 acnt_contract_hashkey, invoice_log_hashkey
)
WITH keyed AS (
    SELECT
        t.id, t.acnt_contract__oid, t.source_event_date,
        sha2(COALESCE(UPPER(TRIM(CAST(t.acnt_contract__oid AS string))), ''), 256) AS acnt_contract_hashkey
    FROM tmp_ows_invoice_log t
    WHERE t.acnt_contract__oid IS NOT NULL
),
src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(k.id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(k.acnt_contract__oid AS string))), ''), 256) AS link_invoice_log_acnt_contract_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(k.id AS string))), ''), 256) AS invoice_log_hashkey,
        p.acnt_contract_hashkey,
        MIN(k.source_event_date) AS source_event_date
    FROM keyed k
    JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_acnt_contract') p
      ON k.acnt_contract_hashkey = p.acnt_contract_hashkey
    GROUP BY 1, 2, 3
)
SELECT d.link_invoice_log_acnt_contract_hashkey, d.source_event_date, current_timestamp(),
       'way4__ows_invoice_log', d.acnt_contract_hashkey, d.invoice_log_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_invoice_log_acnt_contract') t
    ON t.link_invoice_log_acnt_contract_hashkey = d.link_invoice_log_acnt_contract_hashkey;

-- LINK link_invoice_log_doc
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_invoice_log_doc')
(
 link_invoice_log_doc_hashkey, source_event_date, load_timestamp, record_source, document_hashkey,
 invoice_log_hashkey
)
WITH keyed AS (
    SELECT
        t.id, t.doc_id, t.source_event_date,
        sha2(COALESCE(UPPER(TRIM(CAST(t.doc_id AS string))), ''), 256) AS document_hashkey
    FROM tmp_ows_invoice_log t
    WHERE t.doc_id IS NOT NULL
),
src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(k.id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(k.doc_id AS string))), ''), 256) AS link_invoice_log_doc_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(k.id AS string))), ''), 256) AS invoice_log_hashkey,
        p.document_hashkey,
        MIN(k.source_event_date) AS source_event_date
    FROM keyed k
    JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_document') p
      ON k.document_hashkey = p.document_hashkey
    GROUP BY 1, 2, 3
)
SELECT d.link_invoice_log_doc_hashkey, d.source_event_date, current_timestamp(),
       'way4__ows_invoice_log', d.document_hashkey, d.invoice_log_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_invoice_log_doc') t
    ON t.link_invoice_log_doc_hashkey = d.link_invoice_log_doc_hashkey;

-- EFFSAT effsat_link_invoice_log_doc
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.effsat_link_invoice_log_doc')
(link_invoice_log_doc_hashkey, source_event_date, load_timestamp, record_source)
WITH keyed AS (
    SELECT
        t.source_event_date,
        sha2(COALESCE(UPPER(TRIM(CAST(t.id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t.doc_id AS string))), ''), 256) AS link_invoice_log_doc_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t.doc_id AS string))), ''), 256) AS document_hashkey
    FROM tmp_ows_invoice_log t
    WHERE t.doc_id IS NOT NULL
),
src AS (
    SELECT DISTINCT
        k.link_invoice_log_doc_hashkey,
        k.source_event_date
    FROM keyed k
    JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_document') p
      ON k.document_hashkey = p.document_hashkey
)
SELECT d.link_invoice_log_doc_hashkey, d.source_event_date, current_timestamp(), 'way4__ows_invoice_log'
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.effsat_link_invoice_log_doc') t
    ON t.link_invoice_log_doc_hashkey = d.link_invoice_log_doc_hashkey
   AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_ows_invoice_log;
