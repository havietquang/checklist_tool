-- Source: bpm.tcstk_thong_tin_giao_dich | Target: sat_giao_dich_tcstk_thong_tin_giao_dich
-- Full load init | Date col: null
DROP TEMPORARY TABLE IF EXISTS tmp_tcstk_thong_tin_giao_dich; CREATE TEMPORARY TABLE tmp_tcstk_thong_tin_giao_dich AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_gd_omni              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_tao_gd_omni       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao_gd_omni        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tien_de_nghi         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_tien_dn            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tien_de_xuat         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_tien_dx            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tien_hm_pd           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_tien_pd            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai_gd           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(khach_hang_id           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tt_tai_khoan_tc         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tong_so_tien_vay        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_bd_hm              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(han_muc_tc_bd           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hm_tc_con_lai           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hm_dc_da_sd             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tat_toan           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(lai_suat_khi_tat_toan   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tien_khi_tat_toan    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_don_vi_kd_ql         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_don_vi_khoi_tao      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(don_vi_kt               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_kt_hm              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_pd                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_pd                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_gd                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(laisuat                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_tao               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_cap_nhat           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_cap_nhat          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_delete               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai_gd_omni      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_gd_id              AS string))), ''), 256) AS hd_giao_dich_tcstk_thong_tin_giao_dich,
    to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
    gd_id, id, ma_gd_omni, nguoi_tao_gd_omni, ngay_tao_gd_omni, so_tien_de_nghi, loai_tien_dn,
    so_tien_de_xuat, loai_tien_dx, so_tien_hm_pd, loai_tien_pd, trang_thai_gd, khach_hang_id,
    tt_tai_khoan_tc, tong_so_tien_vay, ngay_bd_hm, han_muc_tc_bd, hm_tc_con_lai, hm_dc_da_sd,
    ngay_tat_toan, lai_suat_khi_tat_toan, so_tien_khi_tat_toan, ma_don_vi_kd_ql, ma_don_vi_khoi_tao,
    don_vi_kt, ngay_kt_hm, nguoi_pd, ngay_pd, loai_gd, laisuat, ngay_tao, nguoi_tao,
    ngay_cap_nhat, nguoi_cap_nhat, is_delete, trang_thai_gd_omni, loai_gd_id
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tcstk_thong_tin_giao_dich')
WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tcstk_thong_tin_giao_dich')
(giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 id, ma_gd_omni, nguoi_tao_gd_omni, ngay_tao_gd_omni, so_tien_de_nghi, loai_tien_dn,
 so_tien_de_xuat, loai_tien_dx, so_tien_hm_pd, loai_tien_pd, trang_thai_gd, khach_hang_id,
 tt_tai_khoan_tc, tong_so_tien_vay, ngay_bd_hm, han_muc_tc_bd, hm_tc_con_lai, hm_dc_da_sd,
 ngay_tat_toan, lai_suat_khi_tat_toan, so_tien_khi_tat_toan, ma_don_vi_kd_ql, ma_don_vi_khoi_tao,
 don_vi_kt, ngay_kt_hm, nguoi_pd, ngay_pd, loai_gd, laisuat, ngay_tao, nguoi_tao,
 ngay_cap_nhat, nguoi_cap_nhat, is_delete, trang_thai_gd_omni, loai_gd_id)
WITH deduped AS (SELECT * FROM tmp_tcstk_thong_tin_giao_dich QUALIFY ROW_NUMBER() OVER (PARTITION BY giao_dich_hashkey, hd_giao_dich_tcstk_thong_tin_giao_dich ORDER BY 1) = 1)
SELECT d.giao_dich_hashkey, d.hd_giao_dich_tcstk_thong_tin_giao_dich, d.source_event_date, current_timestamp(), 'bpm__tcstk_thong_tin_giao_dich',
       d.id, d.ma_gd_omni, d.nguoi_tao_gd_omni, d.ngay_tao_gd_omni, d.so_tien_de_nghi, d.loai_tien_dn,
       d.so_tien_de_xuat, d.loai_tien_dx, d.so_tien_hm_pd, d.loai_tien_pd, d.trang_thai_gd, d.khach_hang_id,
       d.tt_tai_khoan_tc, d.tong_so_tien_vay, d.ngay_bd_hm, d.han_muc_tc_bd, d.hm_tc_con_lai, d.hm_dc_da_sd,
       d.ngay_tat_toan, d.lai_suat_khi_tat_toan, d.so_tien_khi_tat_toan, d.ma_don_vi_kd_ql, d.ma_don_vi_khoi_tao,
       d.don_vi_kt, d.ngay_kt_hm, d.nguoi_pd, d.ngay_pd, d.loai_gd, d.laisuat, d.ngay_tao, d.nguoi_tao,
       d.ngay_cap_nhat, d.nguoi_cap_nhat, d.is_delete, d.trang_thai_gd_omni, d.loai_gd_id
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tcstk_thong_tin_giao_dich') t
    ON t.giao_dich_hashkey = d.giao_dich_hashkey AND t.hashdiff = d.hd_giao_dich_tcstk_thong_tin_giao_dich;

DROP TEMPORARY TABLE IF EXISTS tmp_tcstk_thong_tin_giao_dich;
