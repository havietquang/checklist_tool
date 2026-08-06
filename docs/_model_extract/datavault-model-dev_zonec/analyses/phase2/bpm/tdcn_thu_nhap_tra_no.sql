-- Source: bpm.tdcn_thu_nhap_tra_no | Target: sat_giao_dich_tdcn_thu_nhap_tra_no
-- Date range: 20250101 -> 20250131 | Date col: DATADATE (yyyyMMdd)
DROP TEMPORARY TABLE IF EXISTS tmp_tdcn_thu_nhap_tra_no; CREATE TEMPORARY TABLE tmp_tdcn_thu_nhap_tra_no AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(thu_nhap_cua              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(chi_tiet_nguon_tn          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tien                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngoai_le_thu_nhap_tra_no   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(noi_dung_ngoai_le          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(chung_tu_nguon_thu         AS string))), ''), 256) AS hd_giao_dich_tdcn_thu_nhap_tra_no,
    DATADATE AS data_date,
    to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
    CAST(id AS string) AS ma_key,
    gd_id, thu_nhap_cua, chi_tiet_nguon_tn, so_tien, ngay_tao,
    ngoai_le_thu_nhap_tra_no, noi_dung_ngoai_le, chung_tu_nguon_thu
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tdcn_thu_nhap_tra_no')
WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tdcn_thu_nhap_tra_no')
(giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, thu_nhap_cua, chi_tiet_nguon_tn, so_tien, ngay_tao,
 ngoai_le_thu_nhap_tra_no, noi_dung_ngoai_le, chung_tu_nguon_thu)
WITH deduped AS (SELECT * FROM tmp_tdcn_thu_nhap_tra_no QUALIFY ROW_NUMBER() OVER (PARTITION BY giao_dich_hashkey, ma_key, hd_giao_dich_tdcn_thu_nhap_tra_no ORDER BY data_date) = 1)
SELECT d.giao_dich_hashkey, d.hd_giao_dich_tdcn_thu_nhap_tra_no, d.source_event_date, current_timestamp(), 'bpm__tdcn_thu_nhap_tra_no',
       d.ma_key, d.thu_nhap_cua, d.chi_tiet_nguon_tn, d.so_tien, d.ngay_tao,
       d.ngoai_le_thu_nhap_tra_no, d.noi_dung_ngoai_le, d.chung_tu_nguon_thu
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tdcn_thu_nhap_tra_no') t
    ON t.giao_dich_hashkey = d.giao_dich_hashkey AND t.ma_key = d.ma_key AND t.hashdiff = d.hd_giao_dich_tdcn_thu_nhap_tra_no;

DROP TEMPORARY TABLE IF EXISTS tmp_tdcn_thu_nhap_tra_no;
