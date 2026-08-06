-- Source: way4.ows_usage_action | Target: hub_usage_action, sat_usage_action_information, sat_usage_action_date, sat_usage_action_state
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_ows_usage_action;
CREATE TEMPORARY TABLE tmp_ows_usage_action AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS usage_action_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(event_type          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(event_type_next     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(con_cat             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(group_code          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(custom_event_code   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(event_details       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(base_amount         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(base_curr           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(fee_type            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(posting_status      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cl_stop_list        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(client_stop_list    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(next_action         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(switch_tag          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(standing_order__id  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(usage_limiter__id   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(usage_action__oid   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(process_log__id     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(target_doc          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(partition_key       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acnt_contract__id   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(doc                 AS string))), ''), 256) AS hd_usage_action_information,
    sha2(COALESCE(UPPER(TRIM(CAST(record_date       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(start_date        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(end_date          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(start_local_date  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(end_local_date    AS string))), ''), 256) AS hd_usage_action_date,
    sha2(COALESCE(UPPER(TRIM(CAST(old_status    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(new_status    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_pack      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(new_pack      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_scheme    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(new_scheme    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_beh_type  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(new_beh_type  AS string))), ''), 256) AS hd_usage_action_state,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    event_type, event_type_next, con_cat, group_code, custom_event_code, event_details,
    base_amount, base_curr, fee_type, posting_status, cl_stop_list, client_stop_list,
    next_action, switch_tag, standing_order__id, usage_limiter__id, usage_action__oid,
    process_log__id, target_doc, partition_key, acnt_contract__id, doc,
    record_date, start_date, end_date, start_local_date, end_local_date,
    old_status, new_status, old_pack, new_pack, old_scheme, new_scheme, old_beh_type, new_beh_type
FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_usage_action')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- HUB: hub_usage_action
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_usage_action')
(usage_action_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_ows_usage_action QUALIFY ROW_NUMBER() OVER (PARTITION BY usage_action_hashkey ORDER BY data_date) = 1)
SELECT d.usage_action_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 'way4__ows_usage_action'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_usage_action') t
    ON t.usage_action_hashkey = d.usage_action_hashkey;

-- SAT: sat_usage_action_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_usage_action_information')
(
 usage_action_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 acnt_contract__id, base_amount, base_curr, cl_stop_list, client_stop_list, con_cat,
 custom_event_code, doc, event_details, event_type, event_type_next, fee_type, group_code,
 next_action, partition_key, posting_status, process_log__id, standing_order__id, switch_tag,
 target_doc, usage_action__oid, usage_limiter__id
)
WITH deduped AS (SELECT * FROM tmp_ows_usage_action QUALIFY ROW_NUMBER() OVER (PARTITION BY usage_action_hashkey, hd_usage_action_information ORDER BY data_date) = 1)
SELECT d.usage_action_hashkey, d.hd_usage_action_information, d.source_event_date,
       current_timestamp(), 'way4__ows_usage_action', d.acnt_contract__id, d.base_amount,
       d.base_curr, d.cl_stop_list, d.client_stop_list, d.con_cat, d.custom_event_code, d.doc,
       d.event_details, d.event_type, d.event_type_next, d.fee_type, d.group_code, d.next_action,
       d.partition_key, d.posting_status, d.process_log__id, d.standing_order__id, d.switch_tag,
       d.target_doc, d.usage_action__oid, d.usage_limiter__id
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_usage_action_information') t
    ON t.usage_action_hashkey = d.usage_action_hashkey AND t.hashdiff = d.hd_usage_action_information;

-- SAT: sat_usage_action_date
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_usage_action_date')
(
 usage_action_hashkey, hashdiff, source_event_date, load_timestamp, record_source, end_date,
 end_local_date, record_date, start_date, start_local_date
)
WITH deduped AS (SELECT * FROM tmp_ows_usage_action QUALIFY ROW_NUMBER() OVER (PARTITION BY usage_action_hashkey, hd_usage_action_date ORDER BY data_date) = 1)
SELECT d.usage_action_hashkey, d.hd_usage_action_date, d.source_event_date, current_timestamp(),
       'way4__ows_usage_action', d.end_date, d.end_local_date, d.record_date, d.start_date,
       d.start_local_date
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_usage_action_date') t
    ON t.usage_action_hashkey = d.usage_action_hashkey AND t.hashdiff = d.hd_usage_action_date;

-- SAT: sat_usage_action_state
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_usage_action_state')
(
 usage_action_hashkey, hashdiff, source_event_date, load_timestamp, record_source, new_beh_type,
 new_pack, new_scheme, new_status, old_beh_type, old_pack, old_scheme, old_status
)
WITH deduped AS (SELECT * FROM tmp_ows_usage_action QUALIFY ROW_NUMBER() OVER (PARTITION BY usage_action_hashkey, hd_usage_action_state ORDER BY data_date) = 1)
SELECT d.usage_action_hashkey, d.hd_usage_action_state, d.source_event_date, current_timestamp(),
       'way4__ows_usage_action', d.new_beh_type, d.new_pack, d.new_scheme, d.new_status,
       d.old_beh_type, d.old_pack, d.old_scheme, d.old_status
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_usage_action_state') t
    ON t.usage_action_hashkey = d.usage_action_hashkey AND t.hashdiff = d.hd_usage_action_state;

-- LINK link_usage_action_acnt_contract
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_usage_action_acnt_contract')
(
 link_usage_action_acnt_contract_hashkey, source_event_date, load_timestamp, record_source,
 acnt_contract_hashkey, usage_action_hashkey
)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(t.id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t.acnt_contract__id AS string))), ''), 256) AS link_usage_action_acnt_contract_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t.id AS string))), ''), 256) AS usage_action_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t.acnt_contract__id AS string))), ''), 256) AS acnt_contract_hashkey,
        t.source_event_date
    FROM tmp_ows_usage_action t
    JOIN (SELECT DISTINCT id, data_date FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_acnt_contract') WHERE amnd_state = 'A' AND id IS NOT NULL) p
      ON t.acnt_contract__id = p.id AND p.data_date = t.data_date
    WHERE t.acnt_contract__id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY t.id, t.acnt_contract__id ORDER BY t.data_date) = 1
)
SELECT d.link_usage_action_acnt_contract_hashkey, d.source_event_date, current_timestamp(),
       'way4__ows_usage_action', d.acnt_contract_hashkey, d.usage_action_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_usage_action_acnt_contract') t
    ON t.link_usage_action_acnt_contract_hashkey = d.link_usage_action_acnt_contract_hashkey;

-- LINK link_usage_action_document
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_usage_action_document')
(
 link_usage_action_document_hashkey, source_event_date, load_timestamp, record_source,
 document_hashkey, usage_action_hashkey
)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(t.id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t.doc AS string))), ''), 256) AS link_usage_action_document_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t.id AS string))), ''), 256) AS usage_action_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t.doc AS string))), ''), 256) AS document_hashkey,
        t.source_event_date
    FROM tmp_ows_usage_action t
    JOIN (SELECT DISTINCT id, data_date FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_doc') WHERE amnd_state = 'A' AND id IS NOT NULL) p
      ON t.doc = p.id AND p.data_date = t.data_date
    WHERE t.doc IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY t.id, t.doc ORDER BY t.data_date) = 1
)
SELECT d.link_usage_action_document_hashkey, d.source_event_date, current_timestamp(),
       'way4__ows_usage_action', d.document_hashkey, d.usage_action_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_usage_action_document') t
    ON t.link_usage_action_document_hashkey = d.link_usage_action_document_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_ows_usage_action;
