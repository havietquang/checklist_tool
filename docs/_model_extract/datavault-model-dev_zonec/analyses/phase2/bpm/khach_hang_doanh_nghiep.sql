-- Source: bpm.khach_hang_doanh_nghiep | Target: sat_khach_hang_doanh_nghiep
-- Full load init | Date col: null
DROP TEMPORARY TABLE IF EXISTS tmp_khach_hang_doanh_nghiep; CREATE TEMPORARY TABLE tmp_khach_hang_doanh_nghiep AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(khach_hang_id AS string))), ''), 256) AS khach_hang_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id                              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_dang_ky_kinh_doanh          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_cap                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(noi_cap                         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thoi_han_hoat_dong              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(giay_phep_nganh_nghe            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_giay_phep_nganh_nghe         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(noi_cap_giay_phep_nganh_nghe    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_cap_giay_phep_nganh_nghe   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hluc_giay_phep_nganh_nghe       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_hoat_dong                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nganh_dang_ky_chinh             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(von_dieu_le                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_dai_dien_phap_luat        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(chuc_vu_nguoi_dd                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_nhan_vien_van_phong          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_nhan_vien_cong_xuong         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(doanh_thu_nam_gan_nhat          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tong_tai_san_nam_gan_nhat       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tong_du_no_tctd                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phan_khuc_khach_hang_id         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_thanh_lap                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dia_chi_dkkd                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nganh_nghe_dky_id               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(giay_chung_nhan_dau_tu          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(doanh_thu_nhom_kh_lien_quan     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(han_muc_rrtd_cua_kh             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dn_co_phat_trien_da_dac_thu     AS string))), ''), 256) AS hd_khach_hang_doanh_nghiep,
    to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
    khach_hang_id, id, ma_dang_ky_kinh_doanh, ngay_cap, noi_cap, thoi_han_hoat_dong,
    giay_phep_nganh_nghe, ma_giay_phep_nganh_nghe, noi_cap_giay_phep_nganh_nghe,
    ngay_cap_giay_phep_nganh_nghe, hluc_giay_phep_nganh_nghe, ngay_hoat_dong,
    nganh_dang_ky_chinh, von_dieu_le, nguoi_dai_dien_phap_luat, chuc_vu_nguoi_dd,
    so_nhan_vien_van_phong, so_nhan_vien_cong_xuong, ngay_tao, trang_thai,
    doanh_thu_nam_gan_nhat, tong_tai_san_nam_gan_nhat, tong_du_no_tctd,
    phan_khuc_khach_hang_id, ngay_thanh_lap, dia_chi_dkkd, nganh_nghe_dky_id,
    giay_chung_nhan_dau_tu, doanh_thu_nhom_kh_lien_quan, han_muc_rrtd_cua_kh,
    dn_co_phat_trien_da_dac_thu
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.khach_hang_doanh_nghiep')
WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND khach_hang_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_khach_hang_doanh_nghiep')
(khach_hang_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 id, ma_dang_ky_kinh_doanh, ngay_cap, noi_cap, thoi_han_hoat_dong,
 giay_phep_nganh_nghe, ma_giay_phep_nganh_nghe, noi_cap_giay_phep_nganh_nghe,
 ngay_cap_giay_phep_nganh_nghe, hluc_giay_phep_nganh_nghe, ngay_hoat_dong,
 nganh_dang_ky_chinh, von_dieu_le, nguoi_dai_dien_phap_luat, chuc_vu_nguoi_dd,
 so_nhan_vien_van_phong, so_nhan_vien_cong_xuong, ngay_tao, trang_thai,
 doanh_thu_nam_gan_nhat, tong_tai_san_nam_gan_nhat, tong_du_no_tctd,
 phan_khuc_khach_hang_id, ngay_thanh_lap, dia_chi_dkkd, nganh_nghe_dky_id,
 giay_chung_nhan_dau_tu, doanh_thu_nhom_kh_lien_quan, han_muc_rrtd_cua_kh,
 dn_co_phat_trien_da_dac_thu)
WITH deduped AS (SELECT * FROM tmp_khach_hang_doanh_nghiep QUALIFY ROW_NUMBER() OVER (PARTITION BY khach_hang_hashkey, hd_khach_hang_doanh_nghiep ORDER BY 1) = 1)
SELECT d.khach_hang_hashkey, d.hd_khach_hang_doanh_nghiep, d.source_event_date, current_timestamp(), 'bpm__khach_hang_doanh_nghiep',
       d.id, d.ma_dang_ky_kinh_doanh, d.ngay_cap, d.noi_cap, d.thoi_han_hoat_dong,
       d.giay_phep_nganh_nghe, d.ma_giay_phep_nganh_nghe, d.noi_cap_giay_phep_nganh_nghe,
       d.ngay_cap_giay_phep_nganh_nghe, d.hluc_giay_phep_nganh_nghe, d.ngay_hoat_dong,
       d.nganh_dang_ky_chinh, d.von_dieu_le, d.nguoi_dai_dien_phap_luat, d.chuc_vu_nguoi_dd,
       d.so_nhan_vien_van_phong, d.so_nhan_vien_cong_xuong, d.ngay_tao, d.trang_thai,
       d.doanh_thu_nam_gan_nhat, d.tong_tai_san_nam_gan_nhat, d.tong_du_no_tctd,
       d.phan_khuc_khach_hang_id, d.ngay_thanh_lap, d.dia_chi_dkkd, d.nganh_nghe_dky_id,
       d.giay_chung_nhan_dau_tu, d.doanh_thu_nhom_kh_lien_quan, d.han_muc_rrtd_cua_kh,
       d.dn_co_phat_trien_da_dac_thu
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_khach_hang_doanh_nghiep') t
    ON t.khach_hang_hashkey = d.khach_hang_hashkey AND t.hashdiff = d.hd_khach_hang_doanh_nghiep;

DROP TEMPORARY TABLE IF EXISTS tmp_khach_hang_doanh_nghiep;
