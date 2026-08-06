-- Source: bpm.tdcn_chi_tiet_san_pham | Target: sat_giao_dich_tdcn_chi_tiet_san_pham
-- Date range: 20250101 -> 20250131 | Date col: DATADATE (yyyyMMdd)
DROP TEMPORARY TABLE IF EXISTS tmp_tdcn_chi_tiet_san_pham; CREATE TEMPORARY TABLE tmp_tdcn_chi_tiet_san_pham AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(san_pham_id      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_san_pham    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dong_xe          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_xe          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gia_tri_ts       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(fast_lane        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(gd_tsbd          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(trang_thai_gd_tsbd AS string))), ''), 256) AS hd_giao_dich_tdcn_chi_tiet_san_pham,
    DATADATE AS data_date,
    to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
    CAST(id AS string) AS ma_key,
    gd_id, san_pham_id, loai_san_pham, dong_xe, loai_xe, gia_tri_ts, fast_lane, gd_tsbd, trang_thai_gd_tsbd
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tdcn_chi_tiet_san_pham')
WHERE gd_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tdcn_chi_tiet_san_pham')
(giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, san_pham_id, loai_san_pham, dong_xe, loai_xe, gia_tri_ts, fast_lane, gd_tsbd, trang_thai_gd_tsbd)
WITH deduped AS (SELECT * FROM tmp_tdcn_chi_tiet_san_pham QUALIFY ROW_NUMBER() OVER (PARTITION BY giao_dich_hashkey, ma_key, hd_giao_dich_tdcn_chi_tiet_san_pham ORDER BY data_date) = 1)
SELECT d.giao_dich_hashkey, d.hd_giao_dich_tdcn_chi_tiet_san_pham, d.source_event_date, current_timestamp(), 'bpm__tdcn_chi_tiet_san_pham',
       d.ma_key, d.san_pham_id, d.loai_san_pham, d.dong_xe, d.loai_xe, d.gia_tri_ts, d.fast_lane, d.gd_tsbd, d.trang_thai_gd_tsbd
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_tdcn_chi_tiet_san_pham') t
    ON t.giao_dich_hashkey = d.giao_dich_hashkey AND t.ma_key = d.ma_key AND t.hashdiff = d.hd_giao_dich_tdcn_chi_tiet_san_pham;

DROP TEMPORARY TABLE IF EXISTS tmp_tdcn_chi_tiet_san_pham;
