-- Source: bpm.tdcn_khoan_cap_td_the | Target: sat_giao_dich_tdcn_khoan_cap_td_the
-- Full load init | Date col: null
DROP TEMPORARY TABLE IF EXISTS tmp_tdcn_khoan_cap_td_the; CREATE TEMPORARY TABLE tmp_tdcn_khoan_cap_td_the AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id                              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nhom_the                       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hm_the_dx                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nghia_vu_tra_no_kh             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dti                            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ltv                            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tong_muc_cap_td_dx             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_sp_co_va_khong_tsbd       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_sp_khong_tsbd             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_sp_thong_thuong           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_sp_thong_thuong_ko_tsbd   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_kh_tai_ocb                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_tao                      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao                       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cap_td_kem_khoan_vay           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hm_the_dx_pd                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_sp_co_va_khong_tsbd_pd    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(rrtd_sp_khong_tsbd_pd          AS string))), ''), 256) AS hd_giao_dich_tdcn_khoan_cap_td_the,
    to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
    gd_id, id, nhom_the, hm_the_dx, nghia_vu_tra_no_kh, dti, ltv, tong_muc_cap_td_dx,
    rrtd_sp_co_va_khong_tsbd, rrtd_sp_khong_tsbd, rrtd_sp_thong_thuong, rrtd_sp_thong_thuong_ko_tsbd,
    rrtd_kh_tai_ocb, nguoi_tao, ngay_tao, cap_td_kem_khoan_vay, hm_the_dx_pd,
    rrtd_sp_co_va_khong_tsbd_pd, rrtd_sp_khong_tsbd_pd
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tdcn_khoan_cap_td_the')
WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tdcn_khoan_cap_td_the')
(giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 id, nhom_the, hm_the_dx, nghia_vu_tra_no_kh, dti, ltv, tong_muc_cap_td_dx,
 rrtd_sp_co_va_khong_tsbd, rrtd_sp_khong_tsbd, rrtd_sp_thong_thuong, rrtd_sp_thong_thuong_ko_tsbd,
 rrtd_kh_tai_ocb, nguoi_tao, ngay_tao, cap_td_kem_khoan_vay, hm_the_dx_pd,
 rrtd_sp_co_va_khong_tsbd_pd, rrtd_sp_khong_tsbd_pd)
WITH deduped AS (SELECT * FROM tmp_tdcn_khoan_cap_td_the QUALIFY ROW_NUMBER() OVER (PARTITION BY giao_dich_hashkey, hd_giao_dich_tdcn_khoan_cap_td_the ORDER BY 1) = 1)
SELECT d.giao_dich_hashkey, d.hd_giao_dich_tdcn_khoan_cap_td_the, d.source_event_date, current_timestamp(), 'bpm__tdcn_khoan_cap_td_the',
       d.id, d.nhom_the, d.hm_the_dx, d.nghia_vu_tra_no_kh, d.dti, d.ltv, d.tong_muc_cap_td_dx,
       d.rrtd_sp_co_va_khong_tsbd, d.rrtd_sp_khong_tsbd, d.rrtd_sp_thong_thuong, d.rrtd_sp_thong_thuong_ko_tsbd,
       d.rrtd_kh_tai_ocb, d.nguoi_tao, d.ngay_tao, d.cap_td_kem_khoan_vay, d.hm_the_dx_pd,
       d.rrtd_sp_co_va_khong_tsbd_pd, d.rrtd_sp_khong_tsbd_pd
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tdcn_khoan_cap_td_the') t
    ON t.giao_dich_hashkey = d.giao_dich_hashkey AND t.hashdiff = d.hd_giao_dich_tdcn_khoan_cap_td_the;

DROP TEMPORARY TABLE IF EXISTS tmp_tdcn_khoan_cap_td_the;
