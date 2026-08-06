-- Source: bpm.tc_stk_thong_tin_tong_hop | Target: sat_giao_dich_tc_stk_thong_tin_tong_hop
-- Full load init | Date col: null
DROP TEMPORARY TABLE IF EXISTS tmp_tc_stk_thong_tin_tong_hop; CREATE TEMPORARY TABLE tmp_tc_stk_thong_tin_tong_hop AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(ma_giao_dich AS string))), ''), 256) AS giao_dich_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_giao_dich        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_kh_de_xuat     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_pd_tk          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_cif              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cmnd                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ho_ten              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tktc             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sdt                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(email               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_stk              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gia_tri_tsbd        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_tsbd             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_bat_dau_hm     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_ket_thuc_hm    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_han_muc          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tien_hm          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_tien           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_trang_thai       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai_bpm      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_phe_duyet      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_phe_duyet     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_xuat_file      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(process_id          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cn_ql_tktc          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cat_tktc            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cn_ql_stk           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ls_so_stk           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(bien_do_ls          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_lien_ket_quyen   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cn_ql_lien_ket_quyen AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tai_khoan_wa        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dien_giai_loi       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_ky             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(transaction_id      AS string))), ''), 256) AS hd_giao_dich_tc_stk_thong_tin_tong_hop,
    to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
    id AS ma_key,
    ma_giao_dich, id, ngay_kh_de_xuat, ngay_pd_tk, so_cif, cmnd, ho_ten, so_tktc, sdt, email,
    so_stk, gia_tri_tsbd, ma_tsbd, ngay_bat_dau_hm, ngay_ket_thuc_hm, ma_han_muc, so_tien_hm,
    loai_tien, ma_trang_thai, trang_thai_bpm, ngay_tao, ngay_phe_duyet, nguoi_phe_duyet,
    ngay_xuat_file, process_id, cn_ql_tktc, cat_tktc, cn_ql_stk, ls_so_stk, bien_do_ls,
    ma_lien_ket_quyen, cn_ql_lien_ket_quyen, tai_khoan_wa, dien_giai_loi, ngay_ky, transaction_id
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tc_stk_thong_tin_tong_hop')
WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND ma_giao_dich IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tc_stk_thong_tin_tong_hop')
(giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, ma_giao_dich, ngay_kh_de_xuat, ngay_pd_tk, so_cif, cmnd, ho_ten, so_tktc, sdt, email,
 so_stk, gia_tri_tsbd, ma_tsbd, ngay_bat_dau_hm, ngay_ket_thuc_hm, ma_han_muc, so_tien_hm,
 loai_tien, ma_trang_thai, trang_thai_bpm, ngay_tao, ngay_phe_duyet, nguoi_phe_duyet,
 ngay_xuat_file, process_id, cn_ql_tktc, cat_tktc, cn_ql_stk, ls_so_stk, bien_do_ls,
 ma_lien_ket_quyen, cn_ql_lien_ket_quyen, tai_khoan_wa, dien_giai_loi, ngay_ky, transaction_id)
WITH deduped AS (SELECT * FROM tmp_tc_stk_thong_tin_tong_hop QUALIFY ROW_NUMBER() OVER (PARTITION BY giao_dich_hashkey, ma_key, hd_giao_dich_tc_stk_thong_tin_tong_hop ORDER BY 1) = 1)
SELECT d.giao_dich_hashkey, d.hd_giao_dich_tc_stk_thong_tin_tong_hop, d.source_event_date, current_timestamp(), 'bpm__tc_stk_thong_tin_tong_hop',
       d.ma_key, d.ma_giao_dich, d.ngay_kh_de_xuat, d.ngay_pd_tk, d.so_cif, d.cmnd, d.ho_ten, d.so_tktc, d.sdt, d.email,
       d.so_stk, d.gia_tri_tsbd, d.ma_tsbd, d.ngay_bat_dau_hm, d.ngay_ket_thuc_hm, d.ma_han_muc, d.so_tien_hm,
       d.loai_tien, d.ma_trang_thai, d.trang_thai_bpm, d.ngay_tao, d.ngay_phe_duyet, d.nguoi_phe_duyet,
       d.ngay_xuat_file, d.process_id, d.cn_ql_tktc, d.cat_tktc, d.cn_ql_stk, d.ls_so_stk, d.bien_do_ls,
       d.ma_lien_ket_quyen, d.cn_ql_lien_ket_quyen, d.tai_khoan_wa, d.dien_giai_loi, d.ngay_ky, d.transaction_id
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tc_stk_thong_tin_tong_hop') t
    ON t.giao_dich_hashkey = d.giao_dich_hashkey AND t.ma_key = d.ma_key AND t.hashdiff = d.hd_giao_dich_tc_stk_thong_tin_tong_hop;

DROP TEMPORARY TABLE IF EXISTS tmp_tc_stk_thong_tin_tong_hop;
