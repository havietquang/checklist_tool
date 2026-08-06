-- Source: bpm.h_pdtd_gdich_ctiet_pduyet | Target: sat_h_pdtd_gdich_ctiet_pduyet
-- Date range: 20250101 -> 20250131 | Date col: datadate (yyyyMMdd)
-- Note: feeder cua hub_pdtd_nhom_giao_dich. Hashkey = hash(nvl(B.ma_giao_dich, nhom_giao_dich_id))
--       resolve qua JOIN pdtd_nhom_giao_dich. Sat multi-active (ma_key = id).
DROP TEMPORARY TABLE IF EXISTS tmp_h_pdtd_gdich_ctiet_pduyet; CREATE TEMPORARY TABLE tmp_h_pdtd_gdich_ctiet_pduyet AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(nvl(B.ma_giao_dich, CAST(A.nhom_giao_dich_id AS string)) AS string))), ''), 256) AS pdtd_nhom_giao_dich_hashkey,
    CAST(nvl(B.ma_giao_dich, CAST(A.nhom_giao_dich_id AS string)) AS string) AS business_key,
    CAST(A.id AS string) AS ma_key,
    sha2(COALESCE(UPPER(TRIM(CAST(A.trang_thai_bat_dau_id  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.ngay_bat_dau          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.ngay_ket_thuc         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.nguoi_thao_tac_id     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.trang_thai_ket_thuc_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.ma_giao_dich          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.nguoi_thao_tac        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.process_id            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.role_id               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.ket_qua_id            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.ten_tac_vu            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.role_tiep_theo_id     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.so_lan                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.thoi_gian_thuc_hien   AS string))), ''), 256) AS hd_h_pdtd_gdich_ctiet_pduyet,
    A.datadate AS data_date,
    to_date(A.datadate, 'yyyyMMdd') AS source_event_date,
    A.trang_thai_bat_dau_id, A.ngay_bat_dau, A.ngay_ket_thuc, A.nguoi_thao_tac_id, A.trang_thai_ket_thuc_id,
    A.ma_giao_dich, A.nguoi_thao_tac, A.process_id, A.role_id, A.ket_qua_id, A.ten_tac_vu,
    A.role_tiep_theo_id, A.so_lan, A.thoi_gian_thuc_hien
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.h_pdtd_gdich_ctiet_pduyet') A
LEFT JOIN IDENTIFIER({{catalog_sourcing}} || '.bpm.pdtd_nhom_giao_dich') B
    ON A.nhom_giao_dich_id = B.id
WHERE A.datadate BETWEEN {{start_date}} AND {{end_date}} AND A.nhom_giao_dich_id <> 0;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_h_pdtd_gdich_ctiet_pduyet')
(pdtd_nhom_giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, trang_thai_bat_dau_id, ngay_bat_dau, ngay_ket_thuc, nguoi_thao_tac_id, trang_thai_ket_thuc_id,
 ma_giao_dich, nguoi_thao_tac, process_id, role_id, ket_qua_id, ten_tac_vu,
 role_tiep_theo_id, so_lan, thoi_gian_thuc_hien)
WITH deduped AS (SELECT * FROM tmp_h_pdtd_gdich_ctiet_pduyet QUALIFY ROW_NUMBER() OVER (PARTITION BY pdtd_nhom_giao_dich_hashkey, ma_key, hd_h_pdtd_gdich_ctiet_pduyet ORDER BY data_date) = 1)
SELECT d.pdtd_nhom_giao_dich_hashkey, d.hd_h_pdtd_gdich_ctiet_pduyet, d.source_event_date, current_timestamp(), 'bpm__h_pdtd_gdich_ctiet_pduyet',
       d.ma_key, d.trang_thai_bat_dau_id, d.ngay_bat_dau, d.ngay_ket_thuc, d.nguoi_thao_tac_id, d.trang_thai_ket_thuc_id,
       d.ma_giao_dich, d.nguoi_thao_tac, d.process_id, d.role_id, d.ket_qua_id, d.ten_tac_vu,
       d.role_tiep_theo_id, d.so_lan, d.thoi_gian_thuc_hien
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_h_pdtd_gdich_ctiet_pduyet') t
    ON t.pdtd_nhom_giao_dich_hashkey = d.pdtd_nhom_giao_dich_hashkey
   AND t.ma_key = d.ma_key
   AND t.hashdiff = d.hd_h_pdtd_gdich_ctiet_pduyet;

DROP TEMPORARY TABLE IF EXISTS tmp_h_pdtd_gdich_ctiet_pduyet;
