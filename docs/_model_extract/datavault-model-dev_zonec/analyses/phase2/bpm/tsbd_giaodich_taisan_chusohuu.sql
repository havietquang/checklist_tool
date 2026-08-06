-- Source: bpm.tsbd_giaodich_taisan_chusohuu | Target: t_link_tsbd_giaodich_taisan_chusohuu
-- Date range: 20250101 -> 20250131 | Date col: NGAY_TAO (str+date)
-- Note: KHONG co hub rieng cho bang nay, chi populate t_link
--       (FK tro ve hub_tsbd_giaodich_chinh / hub_tsbd_tai_san / hub_tsbd_chu_so_huu)

-- T_LINK t_link_tsbd_giaodich_taisan_chusohuu
DROP TEMPORARY TABLE IF EXISTS v_src_tsbd_giaodich; CREATE TEMPORARY TABLE v_src_tsbd_giaodich AS
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(ID AS string))), ''), 256) AS t_link_tsbd_giaodich_taisan_chusohuu_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(ma_giao_dich AS string))), ''), 256) AS tsbd_giaodich_chinh_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(ma_tai_san AS string))), ''), 256) AS tsbd_tai_san_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(csh_id AS string))), ''), 256) AS tsbd_chu_so_huu_hashkey,
        to_date(datadate, 'yyyyMMdd') AS source_event_date,
        giaodich_id, taisan_id, ten_tai_san, taisan_tinh_tp_id, taisan_quan_huyen_id,
        bds_can_cu_dg, bds_ma_can_ho, bds_ngay_cap_cn, so_giay_cn, giayto_to_chuc, giayto_menh_gia, giayto_ky_han,
        quyenphatsinh_ten, quyenphatsinh_sohopdong, vongop_mack, vongop_tochucnhan,
        ptvt_loaiphuongtien_id, ptvt_hangxs, ptvt_bienks, ptvt_congnang, ptvt_tentau, ptvt_sodky, ptvt_taitrong,
        hanghoa_tenquycach, tskhac_tt_taisan, tskhac_ghichu, taisan_mo_ta, taisan_dia_chi,
        nhom_tai_san_id, loai_tai_san_id, ctiet_tai_san_id,
        csh_ho_ten, csh_cmnd, csh_ngay_sinh, trang_thai, nguoi_tao, ngay_tao, dong_xe
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tsbd_giaodich_taisan_chusohuu')
    WHERE datadate BETWEEN {{start_date}} AND {{end_date}}
      AND ID IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY NGAY_TAO) = 1
;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.t_link_tsbd_giaodich_taisan_chusohuu')
(
 t_link_tsbd_giaodich_taisan_chusohuu_hashkey, source_event_date, load_timestamp, record_source,
 tsbd_giaodich_chinh_hashkey, tsbd_tai_san_hashkey, tsbd_chu_so_huu_hashkey, giaodich_id,
 taisan_id, ten_tai_san, taisan_tinh_tp_id, taisan_quan_huyen_id, bds_can_cu_dg, bds_ma_can_ho,
 bds_ngay_cap_cn, so_giay_cn, giayto_to_chuc, giayto_menh_gia, giayto_ky_han, quyenphatsinh_ten,
 quyenphatsinh_sohopdong, vongop_mack, vongop_tochucnhan, ptvt_loaiphuongtien_id, ptvt_hangxs,
 ptvt_bienks, ptvt_congnang, ptvt_tentau, ptvt_sodky, ptvt_taitrong, hanghoa_tenquycach,
 tskhac_tt_taisan, tskhac_ghichu, taisan_mo_ta, taisan_dia_chi, nhom_tai_san_id, loai_tai_san_id,
 ctiet_tai_san_id, csh_ho_ten, csh_cmnd, csh_ngay_sinh, trang_thai, nguoi_tao, ngay_tao, dong_xe
)
SELECT d.t_link_tsbd_giaodich_taisan_chusohuu_hashkey, d.source_event_date, current_timestamp(),
       'bpm__tsbd_giaodich_taisan_chusohuu', d.tsbd_giaodich_chinh_hashkey,
       d.tsbd_tai_san_hashkey, d.tsbd_chu_so_huu_hashkey, d.giaodich_id, d.taisan_id,
       d.ten_tai_san, d.taisan_tinh_tp_id, d.taisan_quan_huyen_id, d.bds_can_cu_dg,
       d.bds_ma_can_ho, d.bds_ngay_cap_cn, d.so_giay_cn, d.giayto_to_chuc, d.giayto_menh_gia,
       d.giayto_ky_han, d.quyenphatsinh_ten, d.quyenphatsinh_sohopdong, d.vongop_mack,
       d.vongop_tochucnhan, d.ptvt_loaiphuongtien_id, d.ptvt_hangxs, d.ptvt_bienks,
       d.ptvt_congnang, d.ptvt_tentau, d.ptvt_sodky, d.ptvt_taitrong, d.hanghoa_tenquycach,
       d.tskhac_tt_taisan, d.tskhac_ghichu, d.taisan_mo_ta, d.taisan_dia_chi, d.nhom_tai_san_id,
       d.loai_tai_san_id, d.ctiet_tai_san_id, d.csh_ho_ten, d.csh_cmnd, d.csh_ngay_sinh,
       d.trang_thai, d.nguoi_tao, d.ngay_tao, d.dong_xe
FROM v_src_tsbd_giaodich d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.t_link_tsbd_giaodich_taisan_chusohuu') t
    ON t.t_link_tsbd_giaodich_taisan_chusohuu_hashkey = d.t_link_tsbd_giaodich_taisan_chusohuu_hashkey;
