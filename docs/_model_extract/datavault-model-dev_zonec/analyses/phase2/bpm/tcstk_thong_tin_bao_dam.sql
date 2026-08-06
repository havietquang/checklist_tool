-- Source: bpm.tcstk_thong_tin_bao_dam | Target: sat_giao_dich_tcstk_thong_tin_bao_dam
-- Full load init | Date col: null
DROP TEMPORARY TABLE IF EXISTS tmp_tcstk_thong_tin_bao_dam; CREATE TEMPORARY TABLE tmp_tcstk_thong_tin_bao_dam AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(ten_tsbd              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_tsbd               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gia_tri_tsbd          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tyle_bao_dam          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai_ts         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_bat_dau_co_hl    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_het_han          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(han_muc_tc_bd         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hm_tc_con_lai         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hm_dc_da_sd           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_tao             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_cap_nhat         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_cap_nhat        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_delete             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(id_ttgd               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(giatri_baodam         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_ms               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_dao_han          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_hm                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_lkq                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai_phong_toa  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(status                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_tien             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(lai_suat              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_so_tk              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ki_han                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ten_san_pham          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(productcode           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(lai_suat_tk           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(stt_so                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thaihm          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ly_do                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hinh_thuc_tt_stk      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_phong_toa          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tai_khoan_so       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(madcaz                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_checkstk           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_tao_ts_bd          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_dieu_chinh         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_phong_toa          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_chi_nhanh_stk      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_giai_toa_ts        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_giaitoa            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_giai_chap_ts       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_giaichap           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_tat_toan           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_tat_toan           AS string))), ''), 256) AS hd_giao_dich_tcstk_thong_tin_bao_dam,
    to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
    CAST(id AS string) AS ma_key,
    gd_id, ten_tsbd, ma_tsbd, gia_tri_tsbd, tyle_bao_dam, trang_thai_ts,
    ngay_bat_dau_co_hl, ngay_het_han, han_muc_tc_bd, hm_tc_con_lai, hm_dc_da_sd,
    ngay_tao, nguoi_tao, ngay_cap_nhat, nguoi_cap_nhat, is_delete, id_ttgd, giatri_baodam,
    ngay_ms, ngay_dao_han, ma_hm, ma_lkq, trang_thai_phong_toa, status, loai_tien, lai_suat,
    so_so_tk, ki_han, ten_san_pham, productcode, lai_suat_tk, stt_so, trang_thaihm, ly_do,
    hinh_thuc_tt_stk, ma_phong_toa, so_tai_khoan_so, madcaz, is_checkstk, is_tao_ts_bd,
    is_dieu_chinh, is_phong_toa, ma_chi_nhanh_stk, is_giai_toa_ts, ma_giaitoa,
    is_giai_chap_ts, ma_giaichap, is_tat_toan, ma_tat_toan
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tcstk_thong_tin_bao_dam')
WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tcstk_thong_tin_bao_dam')
(giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, ten_tsbd, ma_tsbd, gia_tri_tsbd, tyle_bao_dam, trang_thai_ts,
 ngay_bat_dau_co_hl, ngay_het_han, han_muc_tc_bd, hm_tc_con_lai, hm_dc_da_sd,
 ngay_tao, nguoi_tao, ngay_cap_nhat, nguoi_cap_nhat, is_delete, id_ttgd, giatri_baodam,
 ngay_ms, ngay_dao_han, ma_hm, ma_lkq, trang_thai_phong_toa, status, loai_tien, lai_suat,
 so_so_tk, ki_han, ten_san_pham, productcode, lai_suat_tk, stt_so, trang_thaihm, ly_do,
 hinh_thuc_tt_stk, ma_phong_toa, so_tai_khoan_so, madcaz, is_checkstk, is_tao_ts_bd,
 is_dieu_chinh, is_phong_toa, ma_chi_nhanh_stk, is_giai_toa_ts, ma_giaitoa,
 is_giai_chap_ts, ma_giaichap, is_tat_toan, ma_tat_toan)
WITH deduped AS (SELECT * FROM tmp_tcstk_thong_tin_bao_dam QUALIFY ROW_NUMBER() OVER (PARTITION BY giao_dich_hashkey, ma_key, hd_giao_dich_tcstk_thong_tin_bao_dam ORDER BY 1) = 1)
SELECT d.giao_dich_hashkey, d.hd_giao_dich_tcstk_thong_tin_bao_dam, d.source_event_date, current_timestamp(), 'bpm__tcstk_thong_tin_bao_dam',
       d.ma_key, d.ten_tsbd, d.ma_tsbd, d.gia_tri_tsbd, d.tyle_bao_dam, d.trang_thai_ts,
       d.ngay_bat_dau_co_hl, d.ngay_het_han, d.han_muc_tc_bd, d.hm_tc_con_lai, d.hm_dc_da_sd,
       d.ngay_tao, d.nguoi_tao, d.ngay_cap_nhat, d.nguoi_cap_nhat, d.is_delete, d.id_ttgd, d.giatri_baodam,
       d.ngay_ms, d.ngay_dao_han, d.ma_hm, d.ma_lkq, d.trang_thai_phong_toa, d.status, d.loai_tien, d.lai_suat,
       d.so_so_tk, d.ki_han, d.ten_san_pham, d.productcode, d.lai_suat_tk, d.stt_so, d.trang_thaihm, d.ly_do,
       d.hinh_thuc_tt_stk, d.ma_phong_toa, d.so_tai_khoan_so, d.madcaz, d.is_checkstk, d.is_tao_ts_bd,
       d.is_dieu_chinh, d.is_phong_toa, d.ma_chi_nhanh_stk, d.is_giai_toa_ts, d.ma_giaitoa,
       d.is_giai_chap_ts, d.ma_giaichap, d.is_tat_toan, d.ma_tat_toan
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tcstk_thong_tin_bao_dam') t
    ON t.giao_dich_hashkey = d.giao_dich_hashkey AND t.ma_key = d.ma_key AND t.hashdiff = d.hd_giao_dich_tcstk_thong_tin_bao_dam;

DROP TEMPORARY TABLE IF EXISTS tmp_tcstk_thong_tin_bao_dam;
