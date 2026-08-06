-- Source: bpm.h_pdtd_gdich_lsu_pduyet | Target: sat_h_pdtd_gdich_lsu_pduyet
-- Date range: 20250101 -> 20250131 | Date col: datadate (yyyyMMdd)
-- Note: feeder cua hub_pdtd_nhom_giao_dich. Hashkey = hash(nvl(B.ma_giao_dich, nhom_giao_dich_id))
--       resolve qua JOIN pdtd_nhom_giao_dich. Sat multi-active (ma_key = id).
DROP TEMPORARY TABLE IF EXISTS tmp_h_pdtd_gdich_lsu_pduyet; CREATE TEMPORARY TABLE tmp_h_pdtd_gdich_lsu_pduyet AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(nvl(B.ma_giao_dich, CAST(A.nhom_giao_dich_id AS string)) AS string))), ''), 256) AS pdtd_nhom_giao_dich_hashkey,
    CAST(nvl(B.ma_giao_dich, CAST(A.nhom_giao_dich_id AS string)) AS string) AS business_key,
    CAST(A.id AS string) AS ma_key,
    sha2(COALESCE(UPPER(TRIM(CAST(A.dvi_phe_duyet      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.nguoi_phe_duyet    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.ngay_phe_duyet     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.noi_dung_phe_duyet AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.chu_thich          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.trang_thai         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.nhom_id            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tham_quyen         AS string))), ''), 256) AS hd_h_pdtd_gdich_lsu_pduyet,
    A.datadate AS data_date,
    to_date(A.datadate, 'yyyyMMdd') AS source_event_date,
    A.dvi_phe_duyet, A.nguoi_phe_duyet, A.ngay_phe_duyet, A.noi_dung_phe_duyet, A.chu_thich, A.trang_thai,
    A.dang_phe_duyet, A.phe_duyet_id,
    A.noi_dung_phe_duyet1, A.noi_dung_phe_duyet2, A.noi_dung_phe_duyet3, A.noi_dung_phe_duyet4,
    A.noi_dung_phe_duyet5, A.noi_dung_phe_duyet6, A.noi_dung_phe_duyet7, A.noi_dung_phe_duyet8, A.noi_dung_phe_duyet9,
    A.nhom_id, A.tham_quyen
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.h_pdtd_gdich_lsu_pduyet') A
LEFT JOIN IDENTIFIER({{catalog_sourcing}} || '.bpm.pdtd_nhom_giao_dich') B
    ON A.nhom_giao_dich_id = B.id
WHERE A.datadate BETWEEN {{start_date}} AND {{end_date}};

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_h_pdtd_gdich_lsu_pduyet')
(pdtd_nhom_giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, dvi_phe_duyet, nguoi_phe_duyet, ngay_phe_duyet, noi_dung_phe_duyet, chu_thich, trang_thai,
 dang_phe_duyet, phe_duyet_id, noi_dung_phe_duyet1, noi_dung_phe_duyet2, noi_dung_phe_duyet3,
 noi_dung_phe_duyet4, noi_dung_phe_duyet5, noi_dung_phe_duyet6, noi_dung_phe_duyet7, noi_dung_phe_duyet8,
 noi_dung_phe_duyet9, nhom_id, tham_quyen)
WITH deduped AS (SELECT * FROM tmp_h_pdtd_gdich_lsu_pduyet QUALIFY ROW_NUMBER() OVER (PARTITION BY pdtd_nhom_giao_dich_hashkey, ma_key, hd_h_pdtd_gdich_lsu_pduyet ORDER BY data_date) = 1)
SELECT d.pdtd_nhom_giao_dich_hashkey, d.hd_h_pdtd_gdich_lsu_pduyet, d.source_event_date, current_timestamp(), 'bpm__h_pdtd_gdich_lsu_pduyet',
       d.ma_key, d.dvi_phe_duyet, d.nguoi_phe_duyet, d.ngay_phe_duyet, d.noi_dung_phe_duyet, d.chu_thich, d.trang_thai,
       d.dang_phe_duyet, d.phe_duyet_id, d.noi_dung_phe_duyet1, d.noi_dung_phe_duyet2, d.noi_dung_phe_duyet3,
       d.noi_dung_phe_duyet4, d.noi_dung_phe_duyet5, d.noi_dung_phe_duyet6, d.noi_dung_phe_duyet7, d.noi_dung_phe_duyet8,
       d.noi_dung_phe_duyet9, d.nhom_id, d.tham_quyen
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_h_pdtd_gdich_lsu_pduyet') t
    ON t.pdtd_nhom_giao_dich_hashkey = d.pdtd_nhom_giao_dich_hashkey
   AND t.ma_key = d.ma_key
   AND t.hashdiff = d.hd_h_pdtd_gdich_lsu_pduyet;

DROP TEMPORARY TABLE IF EXISTS tmp_h_pdtd_gdich_lsu_pduyet;
