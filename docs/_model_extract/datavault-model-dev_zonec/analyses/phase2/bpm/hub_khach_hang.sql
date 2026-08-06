-- Source: bpm (multi-source hub) | Target: hub_khach_hang
-- Gop tat ca nguon insert vao hub_khach_hang thanh 1 script: union all + dedup theo source_priority (giong model hub_khach_hang)
-- Luu y: nguon priority-1 'khach_hang' khong co script init nen khong gop o day.
DROP TEMPORARY TABLE IF EXISTS v_src_hub_khach_hang;
CREATE TEMPORARY TABLE v_src_hub_khach_hang AS
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(khach_hang_id AS string))), ''), 256) AS khach_hang_hashkey,
        CAST(khach_hang_id AS bigint) AS business_key,
        to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
        'bpm__khach_hang_ca_nhan' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.khach_hang_ca_nhan')
    WHERE khach_hang_id IS NOT NULL

    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(khach_hang_id AS string))), ''), 256) AS khach_hang_hashkey,
        CAST(khach_hang_id AS bigint) AS business_key,
        to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
        'bpm__khach_hang_doanh_nghiep' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.khach_hang_doanh_nghiep')
    WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}}
      AND khach_hang_id IS NOT NULL
;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_khach_hang')
(khach_hang_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (
    SELECT
        khach_hang_hashkey, business_key, source_event_date, record_source,
        row_number() OVER (PARTITION BY khach_hang_hashkey ORDER BY source_priority) AS rn
    FROM v_src_hub_khach_hang
    WHERE business_key IS NOT NULL AND trim(CAST(business_key AS string)) <> ''
)
SELECT d.khach_hang_hashkey, d.business_key, d.source_event_date, current_timestamp(), d.record_source
FROM (SELECT * FROM deduped WHERE rn = 1) d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_khach_hang') t
    ON t.khach_hang_hashkey = d.khach_hang_hashkey;
