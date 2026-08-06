-- Source: bpm.lich_su_giao_dich | Target: sat_lich_su_giao_dich
-- Date range: 20250101 -> 20250131 | Date col: DATADATE (yyyyMMdd)
DROP TEMPORARY TABLE IF EXISTS tmp_lich_su_giao_dich; CREATE TEMPORARY TABLE tmp_lich_su_giao_dich AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(vai_tro_nguoi_xl    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(vai_tro_tiep_theo   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(vai_tro_truoc       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thoi_diem_bat_dau   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thoi_diem_ket_thuc  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ten_tac_vu          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai_ban_dau  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai_ket_thuc AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(luong_id            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ket_qua_xu_ly       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(task_id             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_tao_id        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_cap_nhat       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(chuc_danh           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thoi_gian_xu_ly     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(don_vi_id           AS string))), ''), 256) AS hd_lich_su_giao_dich,
    DATADATE AS data_date,
    to_date(DATADATE, 'yyyyMMdd') AS source_event_date,
    CAST(ls_id AS string) AS ma_key,
    gd_id, vai_tro_nguoi_xl, vai_tro_tiep_theo, vai_tro_truoc, thoi_diem_bat_dau,
    thoi_diem_ket_thuc, ten_tac_vu, trang_thai_ban_dau, trang_thai_ket_thuc, luong_id,
    ket_qua_xu_ly, task_id, nguoi_tao_id, ngay_tao, ngay_cap_nhat, chuc_danh, thoi_gian_xu_ly, don_vi_id
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.lich_su_giao_dich')
WHERE DATADATE BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_lich_su_giao_dich')
(giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, vai_tro_nguoi_xl, vai_tro_tiep_theo, vai_tro_truoc, thoi_diem_bat_dau,
 thoi_diem_ket_thuc, ten_tac_vu, trang_thai_ban_dau, trang_thai_ket_thuc, luong_id,
 ket_qua_xu_ly, task_id, nguoi_tao_id, ngay_tao, ngay_cap_nhat, chuc_danh, thoi_gian_xu_ly, don_vi_id)
WITH deduped AS (SELECT * FROM tmp_lich_su_giao_dich QUALIFY ROW_NUMBER() OVER (PARTITION BY giao_dich_hashkey, ma_key, hd_lich_su_giao_dich ORDER BY data_date) = 1)
SELECT d.giao_dich_hashkey, d.hd_lich_su_giao_dich, d.source_event_date, current_timestamp(), 'bpm__lich_su_giao_dich',
       d.ma_key, d.vai_tro_nguoi_xl, d.vai_tro_tiep_theo, d.vai_tro_truoc, d.thoi_diem_bat_dau,
       d.thoi_diem_ket_thuc, d.ten_tac_vu, d.trang_thai_ban_dau, d.trang_thai_ket_thuc, d.luong_id,
       d.ket_qua_xu_ly, d.task_id, d.nguoi_tao_id, d.ngay_tao, d.ngay_cap_nhat, d.chuc_danh, d.thoi_gian_xu_ly, d.don_vi_id
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_lich_su_giao_dich') t
    ON t.giao_dich_hashkey = d.giao_dich_hashkey AND t.ma_key = d.ma_key AND t.hashdiff = d.hd_lich_su_giao_dich;

DROP TEMPORARY TABLE IF EXISTS tmp_lich_su_giao_dich;
