-- Source: bpm.qlns_nguoi_lao_dong_info | Target: sat_qlns_nguoi_lao_dong_info_don_vi (phase2)
-- Full load init | Date col: null
DROP TEMPORARY TABLE IF EXISTS tmp_qlns_nguoi_lao_dong_info; CREATE TEMPORARY TABLE tmp_qlns_nguoi_lao_dong_info AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(ma_nhan_vien AS string))), ''), 256) AS qlns_nguoi_lao_dong_info_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(ho_ten              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_sinh           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gioi_tinh           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_gioi_tinh        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cmnd                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_cap_cmnd       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(noi_cap             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_dien_thoai       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(email_ca_nhan       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(email_co_quan       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dia_chi_thuong_tru  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trinh_do            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(chuyen_nganh        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_dong_bo        AS string))), ''), 256) AS hd_qlns_nguoi_lao_dong_info_ca_nhan,
    sha2(COALESCE(UPPER(TRIM(CAST(khoi               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_khoi            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(don_vi             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_don_vi          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phong_ban          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_phong_ban       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bo_phan            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_bo_phan         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(to_nhom            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_to_nhom         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(noi_lam_viec       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(chuc_danh          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_chuc_danh       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(chuc_danh_nnv      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_chuc_danh_nnv   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(chuc_danh_1        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phan_nhom_chuc_danh AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cap_bac            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_cap_bac         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tham_nien_vi_tri   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ten_dang_nhap      AS string))), ''), 256) AS hd_qlns_nguoi_lao_dong_info_don_vi,
    sha2(COALESCE(UPPER(TRIM(CAST(loai_hd_hien_tai              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_loai_hd                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hdld_tu_ngay                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hdld_den_ngay                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_lan_da_ky_hd               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_loai_nhan_vien             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tinh_trang_nhan_vien          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_vao_ocb                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_nghi_phep                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thoi_gian_bat_dau_nghi_phep   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thoi_gian_ket_thuc_nghi_phep  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_ngay_nghi_phep             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ly_do_nghi                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_vao_ocb_chinh_thuc       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_lam_viec_cuoi_cung       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_thoi_viec                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_nop_don_thoi_viec        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thoi_han_den_han_tai_bo_nhiem AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_canh_bao_qt_lam_viec     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tham_nien_nam                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tham_nien_thang              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tuoi                          AS string))), ''), 256) AS hd_qlns_nguoi_lao_dong_info_hop_dong_lao_dong,
    sha2(COALESCE(UPPER(TRIM(CAST(ma_thang_luong     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_ngach_luong     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_bac_luong       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(luong_chuc_danh    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thuong_nang_suat   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thu_nhap           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ho_tro_xang_xe     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phu_cap_doc_hai    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ho_tro_tien_an_giua_ca AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ho_tro_dien_thoai  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phu_cap_thu_hut    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tam_ung_hieu_suat  AS string))), ''), 256) AS hd_qlns_nguoi_lao_dong_info_luong_thuong,
    sha2(COALESCE(UPPER(TRIM(CAST(tinh_trang_ky_luat     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_tinh_trang_ky_luat  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tg_thi_hanh_kl         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tg_ket_thuc_thi_hanh_kl AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(kq_danh_gia_gan_nhat   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(kqdg_ky_truoc          AS string))), ''), 256) AS hd_qlns_nguoi_lao_dong_info_ky_luat,
    to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
    ma_nhan_vien,
    ho_ten, ngay_sinh, gioi_tinh, ma_gioi_tinh, cmnd, ngay_cap_cmnd, noi_cap,
    so_dien_thoai, email_ca_nhan, email_co_quan, dia_chi_thuong_tru, trinh_do, chuyen_nganh, ngay_dong_bo,
    khoi, ma_khoi, don_vi, ma_don_vi, phong_ban, ma_phong_ban, bo_phan, ma_bo_phan,
    to_nhom, ma_to_nhom, noi_lam_viec, chuc_danh, ma_chuc_danh, chuc_danh_nnv, ma_chuc_danh_nnv,
    chuc_danh_1, phan_nhom_chuc_danh, cap_bac, ma_cap_bac, tham_nien_vi_tri, ten_dang_nhap,
    loai_hd_hien_tai, ma_loai_hd, hdld_tu_ngay, hdld_den_ngay, so_lan_da_ky_hd, ma_loai_nhan_vien,
    tinh_trang_nhan_vien, ngay_vao_ocb, loai_nghi_phep, thoi_gian_bat_dau_nghi_phep,
    thoi_gian_ket_thuc_nghi_phep, so_ngay_nghi_phep, ly_do_nghi, ngay_vao_ocb_chinh_thuc,
    ngay_lam_viec_cuoi_cung, ngay_thoi_viec, ngay_nop_don_thoi_viec, thoi_han_den_han_tai_bo_nhiem,
    ngay_canh_bao_qt_lam_viec, tham_nien_nam, tham_nien_thang, tuoi,
    ma_thang_luong, ma_ngach_luong, ma_bac_luong, luong_chuc_danh, thuong_nang_suat, thu_nhap,
    ho_tro_xang_xe, phu_cap_doc_hai, ho_tro_tien_an_giua_ca, ho_tro_dien_thoai, phu_cap_thu_hut, tam_ung_hieu_suat,
    tinh_trang_ky_luat, ma_tinh_trang_ky_luat, tg_thi_hanh_kl, tg_ket_thuc_thi_hanh_kl,
    kq_danh_gia_gan_nhat, kqdg_ky_truoc
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.qlns_nguoi_lao_dong_info')
WHERE ma_nhan_vien IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_qlns_nguoi_lao_dong_info_don_vi')
(qlns_nguoi_lao_dong_info_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 khoi, ma_khoi, don_vi, ma_don_vi, phong_ban, ma_phong_ban, bo_phan, ma_bo_phan,
 to_nhom, ma_to_nhom, noi_lam_viec, chuc_danh, ma_chuc_danh, chuc_danh_nnv, ma_chuc_danh_nnv,
 chuc_danh_1, phan_nhom_chuc_danh, cap_bac, ma_cap_bac, tham_nien_vi_tri, ten_dang_nhap)
WITH deduped AS (SELECT * FROM tmp_qlns_nguoi_lao_dong_info QUALIFY ROW_NUMBER() OVER (PARTITION BY qlns_nguoi_lao_dong_info_hashkey, hd_qlns_nguoi_lao_dong_info_don_vi ORDER BY 1) = 1)
SELECT d.qlns_nguoi_lao_dong_info_hashkey, d.hd_qlns_nguoi_lao_dong_info_don_vi, d.source_event_date, current_timestamp(), 'bpm__qlns_nguoi_lao_dong_info',
       d.khoi, d.ma_khoi, d.don_vi, d.ma_don_vi, d.phong_ban, d.ma_phong_ban, d.bo_phan, d.ma_bo_phan,
       d.to_nhom, d.ma_to_nhom, d.noi_lam_viec, d.chuc_danh, d.ma_chuc_danh, d.chuc_danh_nnv, d.ma_chuc_danh_nnv,
       d.chuc_danh_1, d.phan_nhom_chuc_danh, d.cap_bac, d.ma_cap_bac, d.tham_nien_vi_tri, d.ten_dang_nhap
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_qlns_nguoi_lao_dong_info_don_vi') t
    ON t.qlns_nguoi_lao_dong_info_hashkey = d.qlns_nguoi_lao_dong_info_hashkey AND t.hashdiff = d.hd_qlns_nguoi_lao_dong_info_don_vi;

DROP TEMPORARY TABLE IF EXISTS tmp_qlns_nguoi_lao_dong_info;
