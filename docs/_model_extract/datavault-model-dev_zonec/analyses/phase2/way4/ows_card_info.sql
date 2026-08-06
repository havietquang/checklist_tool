-- Source: way4.ows_card_info | Target: hub_card_info, sat_card_info_information, sat_card_info_production
-- Full load init
DROP TEMPORARY TABLE IF EXISTS tmp_ows_card_info; CREATE TEMPORARY TABLE tmp_ows_card_info AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS card_info_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(card_subtype         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(service_code         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(card_number          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(card_expire          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(card_name            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(company_name         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(seqv_number          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(subtype_code         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(status               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(pin                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(pin_format           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(pvv                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cvc                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cvc2                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(icvv                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(offl_pin             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(pm_parms             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(pm_code              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(file_info__id        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(atc                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(routing_idt          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(apply_dt             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(local_version        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(remote_version       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(event                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trans_status         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(card_track_1         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(add_track_data       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(comment_text         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(offset_data          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(limit_curr           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ext_data             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acnt_contract__oid   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(prev_card            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(parent_card          AS string))), ''), 256) AS hd_card_info_information,
    sha2(COALESCE(UPPER(TRIM(CAST(production_type      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(production_event     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(chip_scheme          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(order_from           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(order_to             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(order_n              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(production_code      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(prod_date            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_from            AS string))), ''), 256) AS hd_card_info_production,
    to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
    id,
    card_subtype, service_code, card_number, card_expire, card_name, company_name, seqv_number,
    subtype_code, status, pin, pin_format, pvv, cvc, cvc2, icvv, offl_pin, pm_parms, pm_code,
    file_info__id, atc, routing_idt, apply_dt, local_version, remote_version, event, trans_status,
    card_track_1, add_track_data, comment_text, offset_data, limit_curr, ext_data,
    acnt_contract__oid, prev_card, parent_card,
    production_type, production_event, chip_scheme, order_from, order_to, order_n,
    production_code, prod_date, date_from
FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_card_info')
WHERE id IS NOT NULL;

-- HUB: hub_card_info
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_card_info')
(card_info_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_ows_card_info QUALIFY ROW_NUMBER() OVER (PARTITION BY card_info_hashkey ORDER BY 1) = 1)
SELECT d.card_info_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 'way4__ows_card_info'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_card_info') t
    ON t.card_info_hashkey = d.card_info_hashkey;

-- SAT: sat_card_info_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_card_info_information')
(
 card_info_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 acnt_contract__oid, add_track_data, apply_dt, atc, card_expire, card_name, card_number,
 card_subtype, card_track_1, comment_text, company_name, cvc, cvc2, event, ext_data,
 file_info__id, icvv, limit_curr, local_version, offl_pin, offset_data, parent_card, pin,
 pin_format, pm_code, pm_parms, prev_card, pvv, remote_version, routing_idt, seqv_number,
 service_code, status, subtype_code, trans_status
)
WITH deduped AS (SELECT * FROM tmp_ows_card_info QUALIFY ROW_NUMBER() OVER (PARTITION BY card_info_hashkey, hd_card_info_information ORDER BY 1) = 1)
SELECT d.card_info_hashkey, d.hd_card_info_information, d.source_event_date, current_timestamp(),
       'way4__ows_card_info', d.acnt_contract__oid, d.add_track_data, d.apply_dt, d.atc,
       d.card_expire, d.card_name, d.card_number, d.card_subtype, d.card_track_1, d.comment_text,
       d.company_name, d.cvc, d.cvc2, d.event, d.ext_data, d.file_info__id, d.icvv, d.limit_curr,
       d.local_version, d.offl_pin, d.offset_data, d.parent_card, d.pin, d.pin_format, d.pm_code,
       d.pm_parms, d.prev_card, d.pvv, d.remote_version, d.routing_idt, d.seqv_number,
       d.service_code, d.status, d.subtype_code, d.trans_status
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_card_info_information') t
    ON t.card_info_hashkey = d.card_info_hashkey AND t.hashdiff = d.hd_card_info_information;

-- SAT: sat_card_info_production
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_card_info_production')
(
 card_info_hashkey, hashdiff, source_event_date, load_timestamp, record_source, chip_scheme,
 date_from, order_from, order_n, order_to, prod_date, production_code, production_event,
 production_type
)
WITH deduped AS (SELECT * FROM tmp_ows_card_info QUALIFY ROW_NUMBER() OVER (PARTITION BY card_info_hashkey, hd_card_info_production ORDER BY 1) = 1)
SELECT d.card_info_hashkey, d.hd_card_info_production, d.source_event_date, current_timestamp(),
       'way4__ows_card_info', d.chip_scheme, d.date_from, d.order_from, d.order_n, d.order_to,
       d.prod_date, d.production_code, d.production_event, d.production_type
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_card_info_production') t
    ON t.card_info_hashkey = d.card_info_hashkey AND t.hashdiff = d.hd_card_info_production;

-- LINK link_card_info_acnt_contract
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_card_info_acnt_contract')
(
 link_card_info_acnt_contract_hashkey, source_event_date, load_timestamp, record_source,
 acnt_contract_hashkey, card_info_hashkey
)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(t.id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t.acnt_contract__oid AS string))), ''), 256) AS link_card_info_acnt_contract_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t.id AS string))), ''), 256) AS card_info_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t.acnt_contract__oid AS string))), ''), 256) AS acnt_contract_hashkey,
        t.source_event_date
    FROM tmp_ows_card_info t
    JOIN (SELECT DISTINCT id FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_acnt_contract') WHERE amnd_state = 'A' AND id IS NOT NULL AND data_date BETWEEN {{start_date}} AND {{end_date}}) p
      ON t.acnt_contract__oid = p.id
    WHERE t.acnt_contract__oid IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY t.id, t.acnt_contract__oid ORDER BY 1) = 1
)
SELECT d.link_card_info_acnt_contract_hashkey, d.source_event_date, current_timestamp(),
       'way4__ows_card_info', d.acnt_contract_hashkey, d.card_info_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_card_info_acnt_contract') t
    ON t.link_card_info_acnt_contract_hashkey = d.link_card_info_acnt_contract_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_ows_card_info;
