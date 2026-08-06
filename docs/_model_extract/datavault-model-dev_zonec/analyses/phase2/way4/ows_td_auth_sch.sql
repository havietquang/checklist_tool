-- Source: way4.ows_td_auth_sch | Target: hub_td_auth_sch, sat_td_auth_sch_information
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_ows_td_auth_sch; CREATE TEMPORARY TABLE tmp_ows_td_auth_sch AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS td_auth_sch_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(auth_idt                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(auth_idt_extension        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(auth_type                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(auth_type_cat             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(auth_type_version_idt     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(name                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(parm_data                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(td_cons__id               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(scheme_rc                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_ready                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_from                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_to                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(apply_dt                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(local_version             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(remote_version            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(client__id                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(acnt_contract__id         AS string))), ''), 256) AS hd_td_auth_sch_information,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    auth_idt, auth_idt_extension, auth_type, auth_type_cat, auth_type_version_idt, name,
    parm_data, td_cons__id, scheme_rc, is_ready, date_from, date_to, apply_dt,
    local_version, remote_version, client__id, acnt_contract__id
FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_td_auth_sch')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL AND amnd_state = 'A';

-- HUB: hub_td_auth_sch
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_td_auth_sch')
(td_auth_sch_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_ows_td_auth_sch QUALIFY ROW_NUMBER() OVER (PARTITION BY td_auth_sch_hashkey ORDER BY data_date) = 1)
SELECT d.td_auth_sch_hashkey, CAST(d.id AS STRING), d.source_event_date, current_timestamp(), 'way4__ows_td_auth_sch'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_td_auth_sch') t
    ON t.td_auth_sch_hashkey = d.td_auth_sch_hashkey;

-- SAT: sat_td_auth_sch_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_td_auth_sch_information')
(
 td_auth_sch_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 acnt_contract__id, apply_dt, auth_idt, auth_idt_extension, auth_type, auth_type_cat,
 auth_type_version_idt, client__id, date_from, date_to, is_ready, local_version, name, parm_data,
 remote_version, scheme_rc, td_cons__id
)
WITH deduped AS (SELECT * FROM tmp_ows_td_auth_sch QUALIFY ROW_NUMBER() OVER (PARTITION BY td_auth_sch_hashkey, hd_td_auth_sch_information ORDER BY data_date) = 1)
SELECT d.td_auth_sch_hashkey, d.hd_td_auth_sch_information, d.source_event_date,
       current_timestamp(), 'way4__ows_td_auth_sch', d.acnt_contract__id, d.apply_dt, d.auth_idt,
       d.auth_idt_extension, d.auth_type, d.auth_type_cat, d.auth_type_version_idt, d.client__id,
       d.date_from, d.date_to, d.is_ready, d.local_version, d.name, d.parm_data, d.remote_version,
       d.scheme_rc, d.td_cons__id
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_td_auth_sch_information') t
    ON t.td_auth_sch_hashkey = d.td_auth_sch_hashkey AND t.hashdiff = d.hd_td_auth_sch_information;

-- LINK link_td_auth_sch_acnt_contract
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_td_auth_sch_acnt_contract')
(
 link_td_auth_sch_acnt_contract_hashkey, source_event_date, load_timestamp, record_source,
 acnt_contract_hashkey, td_auth_sch_hashkey
)
WITH keyed AS (
    SELECT
        t.id, t.acnt_contract__id, t.source_event_date,
        sha2(COALESCE(UPPER(TRIM(CAST(t.acnt_contract__id AS string))), ''), 256) AS acnt_contract_hashkey
    FROM tmp_ows_td_auth_sch t
    WHERE t.acnt_contract__id IS NOT NULL
),
src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(k.id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(k.acnt_contract__id AS string))), ''), 256) AS link_td_auth_sch_acnt_contract_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(k.id AS string))), ''), 256) AS td_auth_sch_hashkey,
        p.acnt_contract_hashkey,
        MIN(k.source_event_date) AS source_event_date
    FROM keyed k
    JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_acnt_contract') p
      ON k.acnt_contract_hashkey = p.acnt_contract_hashkey
    GROUP BY 1, 2, 3
)
SELECT d.link_td_auth_sch_acnt_contract_hashkey, d.source_event_date, current_timestamp(),
       'way4__ows_td_auth_sch', d.acnt_contract_hashkey, d.td_auth_sch_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_td_auth_sch_acnt_contract') t
    ON t.link_td_auth_sch_acnt_contract_hashkey = d.link_td_auth_sch_acnt_contract_hashkey;

-- LINK link_td_auth_sch_client
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_td_auth_sch_client')
(
 link_td_auth_sch_client_hashkey, source_event_date, load_timestamp, record_source,
 client_hashkey, td_auth_sch_hashkey
)
WITH keyed AS (
    SELECT
        t.id, t.client__id, t.source_event_date,
        sha2(COALESCE(UPPER(TRIM(CAST(t.client__id AS string))), ''), 256) AS client_hashkey
    FROM tmp_ows_td_auth_sch t
    WHERE t.client__id IS NOT NULL
),
src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(k.id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(k.client__id AS string))), ''), 256) AS link_td_auth_sch_client_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(k.id AS string))), ''), 256) AS td_auth_sch_hashkey,
        p.client_hashkey,
        MIN(k.source_event_date) AS source_event_date
    FROM keyed k
    JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_client') p
      ON k.client_hashkey = p.client_hashkey
    GROUP BY 1, 2, 3
)
SELECT d.link_td_auth_sch_client_hashkey, d.source_event_date, current_timestamp(),
       'way4__ows_td_auth_sch', d.client_hashkey, d.td_auth_sch_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_td_auth_sch_client') t
    ON t.link_td_auth_sch_client_hashkey = d.link_td_auth_sch_client_hashkey;

-- EFFSAT effsat_link_td_auth_sch_acnt_contract
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.effsat_link_td_auth_sch_acnt_contract')
(link_td_auth_sch_acnt_contract_hashkey, source_event_date, load_timestamp, record_source)
WITH keyed AS (
    SELECT
        t.source_event_date,
        sha2(COALESCE(UPPER(TRIM(CAST(t.id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t.acnt_contract__id AS string))), ''), 256) AS link_td_auth_sch_acnt_contract_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t.acnt_contract__id AS string))), ''), 256) AS acnt_contract_hashkey
    FROM tmp_ows_td_auth_sch t
    WHERE t.acnt_contract__id IS NOT NULL
),
src AS (
    SELECT DISTINCT
        k.link_td_auth_sch_acnt_contract_hashkey,
        k.source_event_date
    FROM keyed k
    JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_acnt_contract') p
      ON k.acnt_contract_hashkey = p.acnt_contract_hashkey
)
SELECT d.link_td_auth_sch_acnt_contract_hashkey, d.source_event_date, current_timestamp(), 'way4__ows_td_auth_sch'
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.effsat_link_td_auth_sch_acnt_contract') t
    ON t.link_td_auth_sch_acnt_contract_hashkey = d.link_td_auth_sch_acnt_contract_hashkey
   AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_ows_td_auth_sch;
