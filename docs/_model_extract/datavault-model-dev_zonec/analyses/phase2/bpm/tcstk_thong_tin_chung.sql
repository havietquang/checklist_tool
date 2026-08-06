-- Source: bpm.tcstk_thong_tin_chung | Target: sat_giao_dich_tcstk_thong_tin_chung
-- Full load init | Date col: null
DROP TEMPORARY TABLE IF EXISTS tmp_tcstk_thong_tin_chung; CREATE TEMPORARY TABLE tmp_tcstk_thong_tin_chung AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_gd_omni            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_tao_gd_omni     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao_gd_omni      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tien_de_nghi       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_tien_dn          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tien_de_xuat       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_tien_dx          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tien_hm_pd         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_tien_pd          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai_gd         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_bd_hm            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_kt_hm            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_pd              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_pd               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_gd               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_tao             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_cap_nhat         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_cap_nhat        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_delete             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai_gd_omni    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(action                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tkwa                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(biendols              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_kh_dx            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_hm                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_lkq                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_don_vi_khoi_tao    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(decesion              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(don_vi_khoi_tao       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(next_decesion         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_cif               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ten_kh               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai_hoat_dong  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tk_tc             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(email                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sodt                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(laisuat              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_tat_toan          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nghiep_vu            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_gd_mo             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(no_goc               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(no_lai               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(du_no_goc_api        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(du_no_lai_api        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tat_toan        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tong_du_no           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_tien            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(list_tai_lieu        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(list_ts              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_tao_tk_tc         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_tao_lkq           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_tao_hm            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_cai_dat_hm        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_tao_wa            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_gan_hm            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_dc_hm_tc          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_go_hm_tc          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_kep_lai           AS string))), ''), 256) AS hd_giao_dich_tcstk_thong_tin_chung,
    to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
    gd_id, id, ma_gd_omni, nguoi_tao_gd_omni, ngay_tao_gd_omni, so_tien_de_nghi, loai_tien_dn,
    so_tien_de_xuat, loai_tien_dx, so_tien_hm_pd, loai_tien_pd, trang_thai_gd, ngay_bd_hm,
    ngay_kt_hm, nguoi_pd, ngay_pd, loai_gd, ngay_tao, nguoi_tao, ngay_cap_nhat, nguoi_cap_nhat,
    is_delete, trang_thai_gd_omni, action, tkwa, biendols, ngay_kh_dx, ma_hm, ma_lkq,
    ma_don_vi_khoi_tao, decesion, don_vi_khoi_tao, next_decesion, so_cif, ten_kh,
    trang_thai_hoat_dong, so_tk_tc, email, sodt, trang_thai, laisuat, is_tat_toan, nghiep_vu,
    ma_gd_mo, no_goc, no_lai, du_no_goc_api, du_no_lai_api, ngay_tat_toan, tong_du_no,
    loai_tien, list_tai_lieu, list_ts, is_tao_tk_tc, is_tao_lkq, is_tao_hm, is_cai_dat_hm,
    is_tao_wa, is_gan_hm, is_dc_hm_tc, is_go_hm_tc, is_kep_lai
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tcstk_thong_tin_chung')
WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tcstk_thong_tin_chung')
(giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 id, ma_gd_omni, nguoi_tao_gd_omni, ngay_tao_gd_omni, so_tien_de_nghi, loai_tien_dn,
 so_tien_de_xuat, loai_tien_dx, so_tien_hm_pd, loai_tien_pd, trang_thai_gd, ngay_bd_hm,
 ngay_kt_hm, nguoi_pd, ngay_pd, loai_gd, ngay_tao, nguoi_tao, ngay_cap_nhat, nguoi_cap_nhat,
 is_delete, trang_thai_gd_omni, action, tkwa, biendols, ngay_kh_dx, ma_hm, ma_lkq,
 ma_don_vi_khoi_tao, decesion, don_vi_khoi_tao, next_decesion, so_cif, ten_kh,
 trang_thai_hoat_dong, so_tk_tc, email, sodt, trang_thai, laisuat, is_tat_toan, nghiep_vu,
 ma_gd_mo, no_goc, no_lai, du_no_goc_api, du_no_lai_api, ngay_tat_toan, tong_du_no,
 loai_tien, list_tai_lieu, list_ts, is_tao_tk_tc, is_tao_lkq, is_tao_hm, is_cai_dat_hm,
 is_tao_wa, is_gan_hm, is_dc_hm_tc, is_go_hm_tc, is_kep_lai)
WITH deduped AS (SELECT * FROM tmp_tcstk_thong_tin_chung QUALIFY ROW_NUMBER() OVER (PARTITION BY giao_dich_hashkey, hd_giao_dich_tcstk_thong_tin_chung ORDER BY 1) = 1)
SELECT d.giao_dich_hashkey, d.hd_giao_dich_tcstk_thong_tin_chung, d.source_event_date, current_timestamp(), 'bpm__tcstk_thong_tin_chung',
       d.id, d.ma_gd_omni, d.nguoi_tao_gd_omni, d.ngay_tao_gd_omni, d.so_tien_de_nghi, d.loai_tien_dn,
       d.so_tien_de_xuat, d.loai_tien_dx, d.so_tien_hm_pd, d.loai_tien_pd, d.trang_thai_gd, d.ngay_bd_hm,
       d.ngay_kt_hm, d.nguoi_pd, d.ngay_pd, d.loai_gd, d.ngay_tao, d.nguoi_tao, d.ngay_cap_nhat, d.nguoi_cap_nhat,
       d.is_delete, d.trang_thai_gd_omni, d.action, d.tkwa, d.biendols, d.ngay_kh_dx, d.ma_hm, d.ma_lkq,
       d.ma_don_vi_khoi_tao, d.decesion, d.don_vi_khoi_tao, d.next_decesion, d.so_cif, d.ten_kh,
       d.trang_thai_hoat_dong, d.so_tk_tc, d.email, d.sodt, d.trang_thai, d.laisuat, d.is_tat_toan, d.nghiep_vu,
       d.ma_gd_mo, d.no_goc, d.no_lai, d.du_no_goc_api, d.du_no_lai_api, d.ngay_tat_toan, d.tong_du_no,
       d.loai_tien, d.list_tai_lieu, d.list_ts, d.is_tao_tk_tc, d.is_tao_lkq, d.is_tao_hm, d.is_cai_dat_hm,
       d.is_tao_wa, d.is_gan_hm, d.is_dc_hm_tc, d.is_go_hm_tc, d.is_kep_lai
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tcstk_thong_tin_chung') t
    ON t.giao_dich_hashkey = d.giao_dich_hashkey AND t.hashdiff = d.hd_giao_dich_tcstk_thong_tin_chung;

DROP TEMPORARY TABLE IF EXISTS tmp_tcstk_thong_tin_chung;
