-- Source: bpm.tdcn_sp_nhu_cau_td | Target: sat_giao_dich_tdcn_sp_nhu_cau_td
-- Date range: 20250101 -> 20250131 | Date col: DATADATE (yyyyMMdd)
DROP TEMPORARY TABLE IF EXISTS tmp_tdcn_sp_nhu_cau_td; CREATE TEMPORARY TABLE tmp_tdcn_sp_nhu_cau_td AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(san_pham_id                              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_san_pham                            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phan_nhom_kh_theo_sp                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phuong_thuc_cho_vay                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ty_le_vay                                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tong_nhu_cau_von                         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tien_vay_dx                           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thoi_gian_vay                            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(lai_suat_vay_du_kien                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(du_no_hien_tai_sp                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_co_tsbd                             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_khong_co_tsbd                       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_tat_ca_sp                           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_tat_ca_sp_khong_tsbd                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_sp_thong_thuong                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_sp_thong_thuong_khong_tsbd          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao                                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dong_vay_co_cic                          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tien_pd                               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_co_tsbd_pd                          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_khong_co_tsbd_pd                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_tat_ca_sp_pd                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_tat_ca_sp_khong_tsbd_pd             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_sp_thong_thuong_pd                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_sp_thong_thuong_khong_tsbd_pd       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tong_rrtd_st                             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tong_rrtd_xl                             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dieu_kien_bu_dap                         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_so_ts_tu_von_vay                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_doi_voi_kh_ocb                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(muc_dich_vay                             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_doi_voi_kh_ocb_pd                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_trinhcaptd_lan_nay                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_trinhcaptd_lan_nay_pd               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thoi_gian_an_han                         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(mua_ban_uy_quyen                         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_tat_ca_sp_khong_tsbd_temp           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(khu_vuc_khach_hang                       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phuong_phap_cm_thu_nhap                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(khoan_vay_theo_cs_cbnv                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(muc_dich                                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phuong_phap_cmtn                         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(khoan_vay_cs_cbnv                        AS string))), ''), 256) AS hd_giao_dich_tdcn_sp_nhu_cau_td,
    DATADATE AS data_date,
    to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
    CAST(id AS string) AS ma_key,
    gd_id, san_pham_id, loai_san_pham, phan_nhom_kh_theo_sp, phuong_thuc_cho_vay,
    ty_le_vay, tong_nhu_cau_von, so_tien_vay_dx, thoi_gian_vay, lai_suat_vay_du_kien,
    du_no_hien_tai_sp, rrtd_co_tsbd, rrtd_khong_co_tsbd, rrtd_tat_ca_sp, rrtd_tat_ca_sp_khong_tsbd,
    rrtd_sp_thong_thuong, rrtd_sp_thong_thuong_khong_tsbd, ngay_tao, dong_vay_co_cic, so_tien_pd,
    rrtd_co_tsbd_pd, rrtd_khong_co_tsbd_pd, rrtd_tat_ca_sp_pd, rrtd_tat_ca_sp_khong_tsbd_pd,
    rrtd_sp_thong_thuong_pd, rrtd_sp_thong_thuong_khong_tsbd_pd, tong_rrtd_st, tong_rrtd_xl,
    dieu_kien_bu_dap, nguoi_so_ts_tu_von_vay, rrtd_doi_voi_kh_ocb, muc_dich_vay,
    rrtd_doi_voi_kh_ocb_pd, rrtd_trinhcaptd_lan_nay, rrtd_trinhcaptd_lan_nay_pd,
    thoi_gian_an_han, mua_ban_uy_quyen, rrtd_tat_ca_sp_khong_tsbd_temp, khu_vuc_khach_hang,
    phuong_phap_cm_thu_nhap, khoan_vay_theo_cs_cbnv, muc_dich, phuong_phap_cmtn, khoan_vay_cs_cbnv
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tdcn_sp_nhu_cau_td')
WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tdcn_sp_nhu_cau_td')
(giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, san_pham_id, loai_san_pham, phan_nhom_kh_theo_sp, phuong_thuc_cho_vay,
 ty_le_vay, tong_nhu_cau_von, so_tien_vay_dx, thoi_gian_vay, lai_suat_vay_du_kien,
 du_no_hien_tai_sp, rrtd_co_tsbd, rrtd_khong_co_tsbd, rrtd_tat_ca_sp, rrtd_tat_ca_sp_khong_tsbd,
 rrtd_sp_thong_thuong, rrtd_sp_thong_thuong_khong_tsbd, ngay_tao, dong_vay_co_cic, so_tien_pd,
 rrtd_co_tsbd_pd, rrtd_khong_co_tsbd_pd, rrtd_tat_ca_sp_pd, rrtd_tat_ca_sp_khong_tsbd_pd,
 rrtd_sp_thong_thuong_pd, rrtd_sp_thong_thuong_khong_tsbd_pd, tong_rrtd_st, tong_rrtd_xl,
 dieu_kien_bu_dap, nguoi_so_ts_tu_von_vay, rrtd_doi_voi_kh_ocb, muc_dich_vay,
 rrtd_doi_voi_kh_ocb_pd, rrtd_trinhcaptd_lan_nay, rrtd_trinhcaptd_lan_nay_pd,
 thoi_gian_an_han, mua_ban_uy_quyen, rrtd_tat_ca_sp_khong_tsbd_temp, khu_vuc_khach_hang,
 phuong_phap_cm_thu_nhap, khoan_vay_theo_cs_cbnv, muc_dich, phuong_phap_cmtn, khoan_vay_cs_cbnv)
WITH deduped AS (SELECT * FROM tmp_tdcn_sp_nhu_cau_td QUALIFY ROW_NUMBER() OVER (PARTITION BY giao_dich_hashkey, ma_key, hd_giao_dich_tdcn_sp_nhu_cau_td ORDER BY data_date) = 1)
SELECT d.giao_dich_hashkey, d.hd_giao_dich_tdcn_sp_nhu_cau_td, d.source_event_date, current_timestamp(), 'bpm__tdcn_sp_nhu_cau_td',
       d.ma_key, d.san_pham_id, d.loai_san_pham, d.phan_nhom_kh_theo_sp, d.phuong_thuc_cho_vay,
       d.ty_le_vay, d.tong_nhu_cau_von, d.so_tien_vay_dx, d.thoi_gian_vay, d.lai_suat_vay_du_kien,
       d.du_no_hien_tai_sp, d.rrtd_co_tsbd, d.rrtd_khong_co_tsbd, d.rrtd_tat_ca_sp, d.rrtd_tat_ca_sp_khong_tsbd,
       d.rrtd_sp_thong_thuong, d.rrtd_sp_thong_thuong_khong_tsbd, d.ngay_tao, d.dong_vay_co_cic, d.so_tien_pd,
       d.rrtd_co_tsbd_pd, d.rrtd_khong_co_tsbd_pd, d.rrtd_tat_ca_sp_pd, d.rrtd_tat_ca_sp_khong_tsbd_pd,
       d.rrtd_sp_thong_thuong_pd, d.rrtd_sp_thong_thuong_khong_tsbd_pd, d.tong_rrtd_st, d.tong_rrtd_xl,
       d.dieu_kien_bu_dap, d.nguoi_so_ts_tu_von_vay, d.rrtd_doi_voi_kh_ocb, d.muc_dich_vay,
       d.rrtd_doi_voi_kh_ocb_pd, d.rrtd_trinhcaptd_lan_nay, d.rrtd_trinhcaptd_lan_nay_pd,
       d.thoi_gian_an_han, d.mua_ban_uy_quyen, d.rrtd_tat_ca_sp_khong_tsbd_temp, d.khu_vuc_khach_hang,
       d.phuong_phap_cm_thu_nhap, d.khoan_vay_theo_cs_cbnv, d.muc_dich, d.phuong_phap_cmtn, d.khoan_vay_cs_cbnv
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tdcn_sp_nhu_cau_td') t
    ON t.giao_dich_hashkey = d.giao_dich_hashkey AND t.ma_key = d.ma_key AND t.hashdiff = d.hd_giao_dich_tdcn_sp_nhu_cau_td;

DROP TEMPORARY TABLE IF EXISTS tmp_tdcn_sp_nhu_cau_td;
