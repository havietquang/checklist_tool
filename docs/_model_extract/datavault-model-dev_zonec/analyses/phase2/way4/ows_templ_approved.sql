-- Source: way4.ows_templ_approved | Target: link_templ_approved_acc_templ (phase2)
-- Full load init
DROP TEMPORARY TABLE IF EXISTS tmp_ows_templ_approved;
CREATE TEMPORARY TABLE tmp_ows_templ_approved AS
SELECT
    id, acc_templ__oid,
    to_date({{start_date}}, 'yyyyMMdd') AS source_event_date
FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_templ_approved')
WHERE id IS NOT NULL;

-- LINK link_templ_approved_acc_templ
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_templ_approved_acc_templ')
(
 link_templ_approved_acc_templ_hashkey, source_event_date, load_timestamp, record_source,
 acc_templ_hashkey, templ_approved_hashkey
)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(t.id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t.acc_templ__oid AS string))), ''), 256) AS link_templ_approved_acc_templ_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t.id AS string))), ''), 256) AS templ_approved_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t.acc_templ__oid AS string))), ''), 256) AS acc_templ_hashkey,
        t.source_event_date
    FROM tmp_ows_templ_approved t
    JOIN (SELECT DISTINCT id FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_acc_templ') WHERE amnd_state = 'A' AND id IS NOT NULL) p
      ON t.acc_templ__oid = p.id
    WHERE t.acc_templ__oid IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY t.id, t.acc_templ__oid ORDER BY 1) = 1
)
SELECT d.link_templ_approved_acc_templ_hashkey, d.source_event_date, current_timestamp(),
       'way4__ows_templ_approved', d.acc_templ_hashkey, d.templ_approved_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_templ_approved_acc_templ') t
    ON t.link_templ_approved_acc_templ_hashkey = d.link_templ_approved_acc_templ_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_ows_templ_approved;
