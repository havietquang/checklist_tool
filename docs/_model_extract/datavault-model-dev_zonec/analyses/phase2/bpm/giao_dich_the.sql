-- Source: bpm.giao_dich_the | Target: sat_giao_dich_the
-- Full load init | Date col: null
DROP TEMPORARY TABLE IF EXISTS tmp_giao_dich_the; CREATE TEMPORARY TABLE tmp_giao_dich_the AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id                        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(kh_id                     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_the                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_the                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_the_t24              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_the_chi_tiet         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(ten_in_tren_the           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(han_muc_de_xuat           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(han_muc_phe_duyet         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(dia_chi                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(the_chinh_phu             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tinh_trang_the            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(so_tk_the                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(tinh_trang_tk_the         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(the_pre_approved          AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nhom_cskh                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(hieu_luc_the              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(branch_code               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phat_hanh_the_phu         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(y_kien                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sys_date                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(loai_the_ttt              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(status_code               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(reason_message            AS string))), ''), 256) AS hd_giao_dich_the,
    to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
    id AS ma_key,
    gd_id, id, kh_id, so_the, loai_the, loai_the_t24, loai_the_chi_tiet, ten_in_tren_the,
    han_muc_de_xuat, han_muc_phe_duyet, dia_chi, the_chinh_phu, tinh_trang_the, so_tk_the,
    tinh_trang_tk_the, the_pre_approved, nhom_cskh, hieu_luc_the, branch_code, phat_hanh_the_phu,
    y_kien, sys_date, loai_the_ttt, status_code, reason_message
FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.giao_dich_the')
WHERE gd_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_the')
(giao_dich_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, kh_id, so_the, loai_the, loai_the_t24, loai_the_chi_tiet, ten_in_tren_the,
 han_muc_de_xuat, han_muc_phe_duyet, dia_chi, the_chinh_phu, tinh_trang_the, so_tk_the,
 tinh_trang_tk_the, the_pre_approved, nhom_cskh, hieu_luc_the, branch_code, phat_hanh_the_phu,
 y_kien, sys_date, loai_the_ttt, status_code, reason_message)
WITH deduped AS (SELECT * FROM tmp_giao_dich_the QUALIFY ROW_NUMBER() OVER (PARTITION BY giao_dich_hashkey, ma_key, hd_giao_dich_the ORDER BY 1) = 1)
SELECT d.giao_dich_hashkey, d.hd_giao_dich_the, d.source_event_date, current_timestamp(), 'bpm__giao_dich_the',
       d.ma_key, d.kh_id, d.so_the, d.loai_the, d.loai_the_t24, d.loai_the_chi_tiet, d.ten_in_tren_the,
       d.han_muc_de_xuat, d.han_muc_phe_duyet, d.dia_chi, d.the_chinh_phu, d.tinh_trang_the, d.so_tk_the,
       d.tinh_trang_tk_the, d.the_pre_approved, d.nhom_cskh, d.hieu_luc_the, d.branch_code, d.phat_hanh_the_phu,
       d.y_kien, d.sys_date, d.loai_the_ttt, d.status_code, d.reason_message
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_giao_dich_the') t
    ON t.giao_dich_hashkey = d.giao_dich_hashkey AND t.ma_key = d.ma_key AND t.hashdiff = d.hd_giao_dich_the;

DROP TEMPORARY TABLE IF EXISTS tmp_giao_dich_the;
