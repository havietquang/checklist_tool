-- Source: bpm.tdcn_nguoi_dong_vay | Target: sat_giao_dich_tdcn_nguoi_dong_vay
-- Full load init | Date col: null
DROP TEMPORARY TABLE IF EXISTS tmp_tdcn_nguoi_dong_vay; CREATE TEMPORARY TABLE tmp_tdcn_nguoi_dong_vay AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(parent_id         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sub_id            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_sinh         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(khach_hang_no     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_cif            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(quan_he_id        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(quoc_tich         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(thoi_gian_con_o_vn AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tuoi           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao          AS string))), ''), 256) AS hd_giao_dich_tdcn_nguoi_dong_vay,
    to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
    CAST(id AS string) AS ma_key,
    gd_id, parent_id, sub_id, ngay_sinh, khach_hang_no, so_cif, quan_he_id, quoc_tich,
    thoi_gian_con_o_vn, so_tuoi, ngay_tao
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tdcn_nguoi_dong_vay')
WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tdcn_nguoi_dong_vay')
(giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, parent_id, sub_id, ngay_sinh, khach_hang_no, so_cif, quan_he_id, quoc_tich,
 thoi_gian_con_o_vn, so_tuoi, ngay_tao)
WITH deduped AS (SELECT * FROM tmp_tdcn_nguoi_dong_vay QUALIFY ROW_NUMBER() OVER (PARTITION BY giao_dich_hashkey, ma_key, hd_giao_dich_tdcn_nguoi_dong_vay ORDER BY 1) = 1)
SELECT d.giao_dich_hashkey, d.hd_giao_dich_tdcn_nguoi_dong_vay, d.source_event_date, current_timestamp(), 'bpm__tdcn_nguoi_dong_vay',
       d.ma_key, d.parent_id, d.sub_id, d.ngay_sinh, d.khach_hang_no, d.so_cif, d.quan_he_id, d.quoc_tich,
       d.thoi_gian_con_o_vn, d.so_tuoi, d.ngay_tao
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tdcn_nguoi_dong_vay') t
    ON t.giao_dich_hashkey = d.giao_dich_hashkey AND t.ma_key = d.ma_key AND t.hashdiff = d.hd_giao_dich_tdcn_nguoi_dong_vay;

DROP TEMPORARY TABLE IF EXISTS tmp_tdcn_nguoi_dong_vay;
