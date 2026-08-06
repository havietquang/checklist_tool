-- Source: bpm.tc_stk_lich_su | Target: sat_giao_dich_tc_stk_lich_su
-- Full load init | Date col: null
DROP TEMPORARY TABLE IF EXISTS tmp_tc_stk_lich_su; CREATE TEMPORARY TABLE tmp_tc_stk_lich_su AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(ma_giao_dich AS string))), ''), 256) AS giao_dich_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_giao_dich     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(process_id       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai_bpm   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_phe_duyet   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_phe_duyet  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_xuat_file   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dien_giai_loi_bpm AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao         AS string))), ''), 256) AS hd_giao_dich_tc_stk_lich_su,
    to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
    id AS ma_key,
    ma_giao_dich, id, process_id, trang_thai_bpm, ngay_phe_duyet, nguoi_phe_duyet,
    ngay_xuat_file, dien_giai_loi_bpm, ngay_tao
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tc_stk_lich_su')
WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND ma_giao_dich IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tc_stk_lich_su')
(giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, ma_giao_dich, process_id, trang_thai_bpm, ngay_phe_duyet, nguoi_phe_duyet,
 ngay_xuat_file, dien_giai_loi_bpm, ngay_tao)
WITH deduped AS (SELECT * FROM tmp_tc_stk_lich_su QUALIFY ROW_NUMBER() OVER (PARTITION BY giao_dich_hashkey, ma_key, hd_giao_dich_tc_stk_lich_su ORDER BY 1) = 1)
SELECT d.giao_dich_hashkey, d.hd_giao_dich_tc_stk_lich_su, d.source_event_date, current_timestamp(), 'bpm__tc_stk_lich_su',
       d.ma_key, d.ma_giao_dich, d.process_id, d.trang_thai_bpm, d.ngay_phe_duyet, d.nguoi_phe_duyet,
       d.ngay_xuat_file, d.dien_giai_loi_bpm, d.ngay_tao
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tc_stk_lich_su') t
    ON t.giao_dich_hashkey = d.giao_dich_hashkey AND t.ma_key = d.ma_key AND t.hashdiff = d.hd_giao_dich_tc_stk_lich_su;

DROP TEMPORARY TABLE IF EXISTS tmp_tc_stk_lich_su;
