-- Source: bpm.pdtd_giao_dich_tin_dung | Target: sat_pdtd_giao_dich_tin_dung
-- Date range: 20250101 -> 20250131 | Date col: datadate (yyyyMMdd)
-- Note: feeder cua hub_pdtd_nhom_giao_dich. Hashkey = hash(B.ma_giao_dich) resolve qua
--       INNER JOIN pdtd_nhom_giao_dich (A.nhom_giao_dich = B.id). Sat multi-active (ma_key = gdtd_id).
DROP TEMPORARY TABLE IF EXISTS tmp_pdtd_giao_dich_tin_dung; CREATE TEMPORARY TABLE tmp_pdtd_giao_dich_tin_dung AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(B.ma_giao_dich AS string))), ''), 256) AS pdtd_nhom_giao_dich_hashkey,
    CAST(B.ma_giao_dich AS string) AS business_key,
    CAST(A.gdtd_id AS string) AS ma_key,
    sha2(COALESCE(UPPER(TRIM(CAST(A.so_tien_vay_de_xuat              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tong_hmrr_100                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tong_hmrr_ko_100                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tong_dthu_gan_nhat               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tong_tsan_gan_nhat               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.du_no_vay_tctd                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.ttin_tien_gui                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tvay_la_tgui                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.loai_tsdb                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.phan_loai_tsdb                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.ty_le_dam_bao                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.qche_chovay_bao_khac             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.qdinh_tin_dung                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.cstindung_theokh                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.spham_tindung                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tyle_baodam_ngoaile              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.ngoai_le_cv_nv_ocb               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.pdnl_upload                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.ds_xe_mua_khanga                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.dsdv_banxe_ocb_cnhan             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tsbd                             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.csh_tsbd                         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.ploai_bds                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.dvkd_tpho_trung_uong             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tle_cvay_dgia_tsbd               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.loai_bdsmua                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.loaikh                           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.kh_nocic_12thang                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.diaban_dvkd                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.vitritsbd_khanga                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.mien_bcao_gsat_tdung             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tdiem_bcao_gsat_tdung            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.ngung_qhtd_ocb_nho_6thang        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.ngung_qhtd_ocb_nho_3thang        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.no_qua_han                       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.kqua_bcao_gstd                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tdiem_bcao_gstd_3t               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tong_hmuc_rui_ro                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.loai_tdung_da_cap               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tsbd_hang_hoa                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tdiem_cap_tdung_hon_3thang       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.kh_mien_tdinh_ttiep             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.filedinhkem                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.ngay_tdtt_truocday               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.no_nhom2_12thang                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tthu_dk_pduyet                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.datadate                         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.json_tin_dung_cap_moi            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.json_tai_cap                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.tai_san_dam_bao                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.to_trinh_goc_id                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.loai_hinh_vay                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.nhom_giao_dich                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.loai_giao_dich                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(A.so_tien_da_cap                   AS string))), ''), 256) AS hd_pdtd_giao_dich_tin_dung,
    A.datadate AS data_date,
    to_date(A.datadate, 'yyyyMMdd') AS source_event_date,
    A.so_tien_vay_de_xuat, A.tong_hmrr_100, A.tong_hmrr_ko_100, A.tong_dthu_gan_nhat,
    A.tong_tsan_gan_nhat, A.du_no_vay_tctd, A.ttin_tien_gui, A.tvay_la_tgui, A.loai_tsdb, A.phan_loai_tsdb,
    A.ty_le_dam_bao, A.qche_chovay_bao_khac, A.qdinh_tin_dung, A.cstindung_theokh, A.spham_tindung,
    A.tyle_baodam_ngoaile, A.ngoai_le_cv_nv_ocb, A.pdnl_upload, A.ds_xe_mua_khanga, A.dsdv_banxe_ocb_cnhan,
    A.tsbd, A.csh_tsbd, A.ploai_bds, A.dvkd_tpho_trung_uong, A.tle_cvay_dgia_tsbd, A.loai_bdsmua, A.loaikh,
    A.kh_nocic_12thang, A.diaban_dvkd, A.vitritsbd_khanga, A.mien_bcao_gsat_tdung, A.tdiem_bcao_gsat_tdung,
    A.ngung_qhtd_ocb_nho_6thang, A.ngung_qhtd_ocb_nho_3thang, A.no_qua_han, A.kqua_bcao_gstd,
    A.tdiem_bcao_gstd_3t, A.tong_hmuc_rui_ro, A.loai_tdung_da_cap, A.tsbd_hang_hoa,
    A.tdiem_cap_tdung_hon_3thang, A.kh_mien_tdinh_ttiep, A.filedinhkem, A.ngay_tdtt_truocday,
    A.no_nhom2_12thang, A.tthu_dk_pduyet, A.json_tin_dung_cap_moi, A.json_tai_cap, A.tai_san_dam_bao,
    A.to_trinh_goc_id, A.loai_hinh_vay, A.nhom_giao_dich, A.loai_giao_dich, A.so_tien_da_cap
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.pdtd_giao_dich_tin_dung') A
JOIN IDENTIFIER({{catalog_sourcing}} || '.bpm.pdtd_nhom_giao_dich') B
    ON A.nhom_giao_dich = B.id
WHERE A.datadate BETWEEN {{start_date}} AND {{end_date}} AND B.ma_giao_dich IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_pdtd_giao_dich_tin_dung')
(pdtd_nhom_giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, so_tien_vay_de_xuat, tong_hmrr_100, tong_hmrr_ko_100, tong_dthu_gan_nhat,
 tong_tsan_gan_nhat, du_no_vay_tctd, ttin_tien_gui, tvay_la_tgui, loai_tsdb, phan_loai_tsdb,
 ty_le_dam_bao, qche_chovay_bao_khac, qdinh_tin_dung, cstindung_theokh, spham_tindung,
 tyle_baodam_ngoaile, ngoai_le_cv_nv_ocb, pdnl_upload, ds_xe_mua_khanga, dsdv_banxe_ocb_cnhan,
 tsbd, csh_tsbd, ploai_bds, dvkd_tpho_trung_uong, tle_cvay_dgia_tsbd, loai_bdsmua, loaikh,
 kh_nocic_12thang, diaban_dvkd, vitritsbd_khanga, mien_bcao_gsat_tdung, tdiem_bcao_gsat_tdung,
 ngung_qhtd_ocb_nho_6thang, ngung_qhtd_ocb_nho_3thang, no_qua_han, kqua_bcao_gstd,
 tdiem_bcao_gstd_3t, tong_hmuc_rui_ro, loai_tdung_da_cap, tsbd_hang_hoa,
 tdiem_cap_tdung_hon_3thang, kh_mien_tdinh_ttiep, filedinhkem, ngay_tdtt_truocday,
 no_nhom2_12thang, tthu_dk_pduyet, datadate, json_tin_dung_cap_moi, json_tai_cap, tai_san_dam_bao,
 to_trinh_goc_id, loai_hinh_vay, nhom_giao_dich, loai_giao_dich, so_tien_da_cap)
WITH deduped AS (SELECT * FROM tmp_pdtd_giao_dich_tin_dung QUALIFY ROW_NUMBER() OVER (PARTITION BY pdtd_nhom_giao_dich_hashkey, ma_key, hd_pdtd_giao_dich_tin_dung ORDER BY data_date) = 1)
SELECT d.pdtd_nhom_giao_dich_hashkey, d.hd_pdtd_giao_dich_tin_dung, d.source_event_date, current_timestamp(), 'bpm__pdtd_giao_dich_tin_dung',
       d.ma_key, d.so_tien_vay_de_xuat, d.tong_hmrr_100, d.tong_hmrr_ko_100, d.tong_dthu_gan_nhat,
       d.tong_tsan_gan_nhat, d.du_no_vay_tctd, d.ttin_tien_gui, d.tvay_la_tgui, d.loai_tsdb, d.phan_loai_tsdb,
       d.ty_le_dam_bao, d.qche_chovay_bao_khac, d.qdinh_tin_dung, d.cstindung_theokh, d.spham_tindung,
       d.tyle_baodam_ngoaile, d.ngoai_le_cv_nv_ocb, d.pdnl_upload, d.ds_xe_mua_khanga, d.dsdv_banxe_ocb_cnhan,
       d.tsbd, d.csh_tsbd, d.ploai_bds, d.dvkd_tpho_trung_uong, d.tle_cvay_dgia_tsbd, d.loai_bdsmua, d.loaikh,
       d.kh_nocic_12thang, d.diaban_dvkd, d.vitritsbd_khanga, d.mien_bcao_gsat_tdung, d.tdiem_bcao_gsat_tdung,
       d.ngung_qhtd_ocb_nho_6thang, d.ngung_qhtd_ocb_nho_3thang, d.no_qua_han, d.kqua_bcao_gstd,
       d.tdiem_bcao_gstd_3t, d.tong_hmuc_rui_ro, d.loai_tdung_da_cap, d.tsbd_hang_hoa,
       d.tdiem_cap_tdung_hon_3thang, d.kh_mien_tdinh_ttiep, d.filedinhkem, d.ngay_tdtt_truocday,
       d.no_nhom2_12thang, d.tthu_dk_pduyet, d.data_date, d.json_tin_dung_cap_moi, d.json_tai_cap, d.tai_san_dam_bao,
       d.to_trinh_goc_id, d.loai_hinh_vay, d.nhom_giao_dich, d.loai_giao_dich, d.so_tien_da_cap
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_pdtd_giao_dich_tin_dung') t
    ON t.pdtd_nhom_giao_dich_hashkey = d.pdtd_nhom_giao_dich_hashkey
   AND t.ma_key = d.ma_key
   AND t.hashdiff = d.hd_pdtd_giao_dich_tin_dung;

DROP TEMPORARY TABLE IF EXISTS tmp_pdtd_giao_dich_tin_dung;
