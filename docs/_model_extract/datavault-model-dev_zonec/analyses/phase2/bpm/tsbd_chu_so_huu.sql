-- Source: bpm.tsbd_chu_so_huu | Target: hub_tsbd_chu_so_huu, sat_tsbd_chu_so_huu
-- Full load init | Date col: null
DROP TEMPORARY TABLE IF EXISTS tmp_tsbd_chu_so_huu; CREATE TEMPORARY TABLE tmp_tsbd_chu_so_huu AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(chu_shuu_id AS string))), ''), 256) AS tsbd_chu_so_huu_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(ho_ten           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(cmnd             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dia_chi          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nguoi_tao        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_tao         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ngay_sinh        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t24              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_chu_so_huu  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(isho             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ma_chu_so_huu    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(khach_hang_id    AS string))), ''), 256) AS hd_tsbd_chu_so_huu,
    to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
    chu_shuu_id, ho_ten, cmnd, dia_chi, nguoi_tao, ngay_tao, ngay_sinh, trang_thai,
    t24, loai_chu_so_huu, isho, ma_chu_so_huu, khach_hang_id
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tsbd_chu_so_huu')
WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND chu_shuu_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_tsbd_chu_so_huu')
(tsbd_chu_so_huu_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_tsbd_chu_so_huu QUALIFY ROW_NUMBER() OVER (PARTITION BY tsbd_chu_so_huu_hashkey ORDER BY 1) = 1)
SELECT d.tsbd_chu_so_huu_hashkey, CAST(d.chu_shuu_id AS STRING), d.source_event_date, current_timestamp(), 'bpm__tsbd_chu_so_huu'
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_tsbd_chu_so_huu') t
    ON t.tsbd_chu_so_huu_hashkey = d.tsbd_chu_so_huu_hashkey;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_tsbd_chu_so_huu')
(tsbd_chu_so_huu_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ho_ten, cmnd, dia_chi, nguoi_tao, ngay_tao, ngay_sinh, trang_thai,
 t24, loai_chu_so_huu, isho, ma_chu_so_huu, khach_hang_id)
WITH deduped AS (SELECT * FROM tmp_tsbd_chu_so_huu QUALIFY ROW_NUMBER() OVER (PARTITION BY tsbd_chu_so_huu_hashkey, hd_tsbd_chu_so_huu ORDER BY 1) = 1)
SELECT d.tsbd_chu_so_huu_hashkey, d.hd_tsbd_chu_so_huu, d.source_event_date, current_timestamp(), 'bpm__tsbd_chu_so_huu',
       d.ho_ten, d.cmnd, d.dia_chi, d.nguoi_tao, d.ngay_tao, d.ngay_sinh, d.trang_thai,
       d.t24, d.loai_chu_so_huu, d.isho, d.ma_chu_so_huu, d.khach_hang_id
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_tsbd_chu_so_huu') t
    ON t.tsbd_chu_so_huu_hashkey = d.tsbd_chu_so_huu_hashkey AND t.hashdiff = d.hd_tsbd_chu_so_huu;

DROP TEMPORARY TABLE IF EXISTS tmp_tsbd_chu_so_huu;
