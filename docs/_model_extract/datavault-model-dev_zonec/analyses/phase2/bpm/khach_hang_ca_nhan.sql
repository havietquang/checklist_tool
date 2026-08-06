-- Source: bpm.khach_hang_ca_nhan | Target: sat_khach_hang_ca_nhan
-- Full load init | Date col: null
DROP TEMPORARY TABLE IF EXISTS tmp_khach_hang_ca_nhan; CREATE TEMPORARY TABLE tmp_khach_hang_ca_nhan AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(khach_hang_id AS string))), ''), 256) AS khach_hang_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_sinh                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cmnd                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(noi_cap_cmnd              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_cap_cmnd             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ho_khau_thuong_tru        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(noi_o_hien_tai            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_dien_thoai             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(email                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tinh_trang_hnhan_id       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tinh_trang_hnhan          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ho_chieu                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(can_cuoc_cong_dan         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gioi_tinh                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(visa                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_cap_visa             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_het_han_visa         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_hieu_luc_visa        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(noi_cap_visa              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thoi_han_cu_tru_vn        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_het_han_cmnd         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thu_nhap_hang_thang       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tham_nien_lam_viec        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(the_can_cuoc              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(quoc_tich                 AS string))), ''), 256) AS hd_khach_hang_ca_nhan,
    to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
    khach_hang_id, id, ngay_sinh, cmnd, noi_cap_cmnd, ngay_cap_cmnd, ho_khau_thuong_tru,
    noi_o_hien_tai, so_dien_thoai, email, ngay_tao, trang_thai, tinh_trang_hnhan_id,
    tinh_trang_hnhan, ho_chieu, can_cuoc_cong_dan, gioi_tinh, visa, ngay_cap_visa,
    ngay_het_han_visa, ngay_hieu_luc_visa, noi_cap_visa, thoi_han_cu_tru_vn,
    ngay_het_han_cmnd, thu_nhap_hang_thang, tham_nien_lam_viec, the_can_cuoc, quoc_tich
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.khach_hang_ca_nhan')
WHERE khach_hang_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_khach_hang_ca_nhan')
(khach_hang_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 id, ngay_sinh, cmnd, noi_cap_cmnd, ngay_cap_cmnd, ho_khau_thuong_tru,
 noi_o_hien_tai, so_dien_thoai, email, ngay_tao, trang_thai, tinh_trang_hnhan_id,
 tinh_trang_hnhan, ho_chieu, can_cuoc_cong_dan, gioi_tinh, visa, ngay_cap_visa,
 ngay_het_han_visa, ngay_hieu_luc_visa, noi_cap_visa, thoi_han_cu_tru_vn,
 ngay_het_han_cmnd, thu_nhap_hang_thang, tham_nien_lam_viec, the_can_cuoc, quoc_tich)
WITH deduped AS (SELECT * FROM tmp_khach_hang_ca_nhan QUALIFY ROW_NUMBER() OVER (PARTITION BY khach_hang_hashkey, hd_khach_hang_ca_nhan ORDER BY 1) = 1)
SELECT d.khach_hang_hashkey, d.hd_khach_hang_ca_nhan, d.source_event_date, current_timestamp(), 'bpm__khach_hang_ca_nhan',
       d.id, d.ngay_sinh, d.cmnd, d.noi_cap_cmnd, d.ngay_cap_cmnd, d.ho_khau_thuong_tru,
       d.noi_o_hien_tai, d.so_dien_thoai, d.email, d.ngay_tao, d.trang_thai, d.tinh_trang_hnhan_id,
       d.tinh_trang_hnhan, d.ho_chieu, d.can_cuoc_cong_dan, d.gioi_tinh, d.visa, d.ngay_cap_visa,
       d.ngay_het_han_visa, d.ngay_hieu_luc_visa, d.noi_cap_visa, d.thoi_han_cu_tru_vn,
       d.ngay_het_han_cmnd, d.thu_nhap_hang_thang, d.tham_nien_lam_viec, d.the_can_cuoc, d.quoc_tich
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_khach_hang_ca_nhan') t
    ON t.khach_hang_hashkey = d.khach_hang_hashkey AND t.hashdiff = d.hd_khach_hang_ca_nhan;

DROP TEMPORARY TABLE IF EXISTS tmp_khach_hang_ca_nhan;
