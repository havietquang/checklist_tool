-- Source: way4.ows_entry | Target: link_entry_item (phase2)
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_ows_entry; CREATE TEMPORARY TABLE tmp_ows_entry AS
SELECT
    id, item__id,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date
FROM IDENTIFIER({{catalog_sourcing}} || '.way4.ows_entry')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- LINK link_entry_item
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_entry_item')
(
 link_entry_item_hashkey, source_event_date, load_timestamp, record_source, entry_hashkey,
 item_hashkey
)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(item__id AS string))), ''), 256) AS link_entry_item_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS entry_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(item__id AS string))), ''), 256) AS item_hashkey,
        source_event_date
    FROM tmp_ows_entry
    WHERE item__id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id, item__id ORDER BY data_date) = 1
)
SELECT d.link_entry_item_hashkey, d.source_event_date, current_timestamp(), 'way4__ows_entry',
       d.entry_hashkey, d.item_hashkey
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_entry_item') t
    ON t.link_entry_item_hashkey = d.link_entry_item_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_ows_entry;
