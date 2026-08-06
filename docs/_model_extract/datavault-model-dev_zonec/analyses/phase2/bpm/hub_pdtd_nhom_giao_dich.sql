-- Source: bpm (multi-source hub) | Target: hub_pdtd_nhom_giao_dich
-- Gop tat ca nguon insert vao hub_pdtd_nhom_giao_dich thanh 1 script: union all + dedup theo source_priority (giong model hub_pdtd_nhom_giao_dich)
-- Luu y: nguon priority-1 'pdtd_nhom_giao_dich' khong co script init nen khong gop o day.
DROP TEMPORARY TABLE IF EXISTS v_src_hub_pdtd_nhom_giao_dich;
CREATE TEMPORARY TABLE v_src_hub_pdtd_nhom_giao_dich AS
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(B.ma_giao_dich AS string))), ''), 256) AS pdtd_nhom_giao_dich_hashkey,
        CAST(B.ma_giao_dich AS string) AS business_key,
        to_date(A.datadate, 'yyyyMMdd') AS source_event_date,
        'bpm__pdtd_giao_dich_tin_dung' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.pdtd_giao_dich_tin_dung') A
    JOIN IDENTIFIER({{catalog_sourcing}} || '.bpm.pdtd_nhom_giao_dich') B
        ON A.nhom_giao_dich = B.id
    WHERE A.datadate BETWEEN {{start_date}} AND {{end_date}}
      AND B.ma_giao_dich IS NOT NULL

    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(nvl(B.ma_giao_dich, CAST(A.nhom_giao_dich_id AS string)) AS string))), ''), 256) AS pdtd_nhom_giao_dich_hashkey,
        CAST(nvl(B.ma_giao_dich, CAST(A.nhom_giao_dich_id AS string)) AS string) AS business_key,
        to_date(A.datadate, 'yyyyMMdd') AS source_event_date,
        'bpm__h_pdtd_gdich_lsu_pduyet' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.h_pdtd_gdich_lsu_pduyet') A
    LEFT JOIN IDENTIFIER({{catalog_sourcing}} || '.bpm.pdtd_nhom_giao_dich') B
        ON A.nhom_giao_dich_id = B.id
    WHERE A.datadate BETWEEN {{start_date}} AND {{end_date}}

    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(nvl(B.ma_giao_dich, CAST(A.nhom_giao_dich_id AS string)) AS string))), ''), 256) AS pdtd_nhom_giao_dich_hashkey,
        CAST(nvl(B.ma_giao_dich, CAST(A.nhom_giao_dich_id AS string)) AS string) AS business_key,
        to_date(A.datadate, 'yyyyMMdd') AS source_event_date,
        'bpm__h_pdtd_gdich_ctiet_pduyet' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.h_pdtd_gdich_ctiet_pduyet') A
    LEFT JOIN IDENTIFIER({{catalog_sourcing}} || '.bpm.pdtd_nhom_giao_dich') B
        ON A.nhom_giao_dich_id = B.id
    WHERE A.datadate BETWEEN {{start_date}} AND {{end_date}}
      AND A.nhom_giao_dich_id <> 0
;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_pdtd_nhom_giao_dich')
(pdtd_nhom_giao_dich_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (
    SELECT
        pdtd_nhom_giao_dich_hashkey, business_key, source_event_date, record_source,
        row_number() OVER (PARTITION BY pdtd_nhom_giao_dich_hashkey ORDER BY source_priority) AS rn
    FROM v_src_hub_pdtd_nhom_giao_dich
    WHERE business_key IS NOT NULL AND trim(CAST(business_key AS string)) <> ''
)
SELECT d.pdtd_nhom_giao_dich_hashkey, d.business_key, d.source_event_date, current_timestamp(), d.record_source
FROM (SELECT * FROM deduped WHERE rn = 1) d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_pdtd_nhom_giao_dich') t
    ON t.pdtd_nhom_giao_dich_hashkey = d.pdtd_nhom_giao_dich_hashkey;
