-- =============================================================================
-- Source : ocb_datavault_prod_sourcing.bpm.auth_nhan_vien
-- Target : sat_auth_nhan_vien
-- Hub key: auth_nhan_vien_hashkey (ten_dang_nhap)
-- Hashdiff: [ten_dang_nhap, ten_nguoi_dung, ocb_hrm_uid, trang_thai, ghi_chu,
--            is_lock, ngay_thay_doi, nhan_vien_qly, email, user_id_thay_doi,
--            so_dien_thoai, chuc_danh, diem_min]
-- Note   : bpm.auth_nhan_vien khong co data_date → doc toan bo, dedup by etl_time
-- =============================================================================

TRUNCATE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_auth_nhan_vien;

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_auth_nhan_vien
(auth_nhan_vien_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ten_dang_nhap, ten_nguoi_dung, ocb_hrm_uid, trang_thai, ghi_chu, is_lock,
 ngay_thay_doi, nhan_vien_qly, email, user_id_thay_doi, so_dien_thoai, chuc_danh, diem_min)
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(ten_dang_nhap AS string))), ''), 256) AS auth_nhan_vien_hashkey,
    sha2(
        COALESCE(UPPER(TRIM(CAST(ten_dang_nhap    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(ten_nguoi_dung   AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(ocb_hrm_uid      AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(trang_thai       AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(ghi_chu          AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(is_lock          AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(ngay_thay_doi    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(nhan_vien_qly    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(email            AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(user_id_thay_doi AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(so_dien_thoai    AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(chuc_danh        AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(diem_min         AS string))), '')
    , 256)                                                              AS hashdiff,
    to_date('20210101', 'yyyyMMdd')                                     AS source_event_date,
    current_timestamp(),
    'bpm__auth_nhan_vien',
    ten_dang_nhap, ten_nguoi_dung, ocb_hrm_uid, trang_thai, ghi_chu, is_lock,
    ngay_thay_doi, nhan_vien_qly, email, user_id_thay_doi, so_dien_thoai, chuc_danh, diem_min
FROM ocb_datavault_prod_sourcing.bpm.auth_nhan_vien
WHERE ten_dang_nhap IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY ten_dang_nhap ORDER BY etl_time DESC) = 1;
