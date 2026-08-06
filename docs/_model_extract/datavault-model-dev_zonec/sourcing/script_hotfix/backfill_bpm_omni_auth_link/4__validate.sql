-- =============================================================================
-- VALIDATE - BPM/OMNI Auth & Link
-- T1: NULL check tren cac cot bat buoc
-- T2: Lookup source -> target (LEFT ANTI JOIN), ket qua mong doi: count = 0
-- =============================================================================

-- ============================================================
-- T1: NULL CHECK
-- ============================================================
SELECT 'hub_auth_nhan_vien' AS target, 'null_check' AS test, COUNT(*) AS fail_count
FROM ocb_datavault_prod_cleaned.raw_vault.hub_auth_nhan_vien
WHERE auth_nhan_vien_hashkey IS NULL OR business_key IS NULL OR source_event_date IS NULL
UNION ALL
SELECT 'sat_auth_nhan_vien', 'null_check', COUNT(*)
FROM ocb_datavault_prod_cleaned.raw_vault.sat_auth_nhan_vien
WHERE auth_nhan_vien_hashkey IS NULL OR hashdiff IS NULL OR source_event_date IS NULL
UNION ALL
SELECT 'link_khach_hang_nhan_vien', 'null_check', COUNT(*)
FROM ocb_datavault_prod_cleaned.raw_vault.link_khach_hang_nhan_vien
WHERE link_khach_hang_nhan_vien_hashkey IS NULL OR khach_hang_hashkey IS NULL OR auth_nhan_vien_hashkey IS NULL OR source_event_date IS NULL
UNION ALL
SELECT 'link_omni_user_customer', 'null_check', COUNT(*)
FROM ocb_datavault_prod_cleaned.raw_vault.link_omni_user_customer
WHERE link_omni_user_customer_hashkey IS NULL OR omni_user_hashkey IS NULL OR customer_hashkey IS NULL OR source_event_date IS NULL
ORDER BY target;

-- ============================================================
-- T2: LOOKUP - kiem tra source co record nao chua vao target
-- ============================================================

-- hub_auth_nhan_vien
WITH src AS (
    SELECT sha2(COALESCE(UPPER(TRIM(CAST(ten_dang_nhap AS string))), ''), 256) AS auth_nhan_vien_hashkey
    FROM ocb_datavault_prod_sourcing.bpm.auth_nhan_vien
    WHERE ten_dang_nhap IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ten_dang_nhap ORDER BY etl_time DESC) = 1
)
SELECT 'hub_auth_nhan_vien' AS target, 'lookup' AS test, COUNT(*) AS missing_count
FROM src s LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.hub_auth_nhan_vien t
    ON t.auth_nhan_vien_hashkey = s.auth_nhan_vien_hashkey;

-- sat_auth_nhan_vien
WITH src AS (
    SELECT sha2(COALESCE(UPPER(TRIM(CAST(ten_dang_nhap AS string))), ''), 256) AS auth_nhan_vien_hashkey,
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
           , 256) AS hashdiff
    FROM ocb_datavault_prod_sourcing.bpm.auth_nhan_vien
    WHERE ten_dang_nhap IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ten_dang_nhap ORDER BY etl_time DESC) = 1
)
SELECT 'sat_auth_nhan_vien' AS target, 'lookup' AS test, COUNT(*) AS missing_count
FROM src s LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_auth_nhan_vien t
    ON t.auth_nhan_vien_hashkey = s.auth_nhan_vien_hashkey AND t.hashdiff = s.hashdiff;

-- link_khach_hang_nhan_vien
WITH latest_nv AS (
    SELECT * FROM ocb_datavault_prod_sourcing.bpm.auth_nhan_vien
    WHERE ten_dang_nhap IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY etl_time DESC) = 1
),
kh_dedup AS (
    SELECT * FROM ocb_datavault_prod_sourcing.bpm.khach_hang
    WHERE id IS NOT NULL AND NGAY_TAO IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id, NGAY_TAO ORDER BY etl_time DESC) = 1
),
src AS (
    SELECT sha2(
               COALESCE(UPPER(TRIM(CAST(kh.id            AS string))), '') || '$' ||
               COALESCE(UPPER(TRIM(CAST(nv.ten_dang_nhap AS string))), '')
           , 256) AS link_hashkey
    FROM kh_dedup kh
    INNER JOIN latest_nv nv ON kh.nhan_vien_tao = nv.id
    WHERE nv.ten_dang_nhap IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY kh.id, nv.ten_dang_nhap ORDER BY kh.NGAY_TAO) = 1
)
SELECT 'link_khach_hang_nhan_vien' AS target, 'lookup' AS test, COUNT(*) AS missing_count
FROM src s LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.link_khach_hang_nhan_vien t
    ON t.link_khach_hang_nhan_vien_hashkey = s.link_hashkey;

-- link_omni_user_customer
WITH src AS (
    SELECT sha2(
               COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
               CASE
                   WHEN regexp_extract(additions, '"cif":"([0-9]+)"', 1) IS NULL THEN ''
                   ELSE TRIM(CAST(regexp_extract(additions, '"cif":"([0-9]+)"', 1) AS string))
               END
           , 256) AS link_hashkey
    FROM ocb_datavault_prod_sourcing.omni.en_user
    WHERE id IS NOT NULL
      AND regexp_extract(additions, '"cif":"([0-9]+)"', 1) IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id, regexp_extract(additions, '"cif":"([0-9]+)"', 1) ORDER BY etl_time DESC) = 1
)
SELECT 'link_omni_user_customer' AS target, 'lookup' AS test, COUNT(*) AS missing_count
FROM src s LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.link_omni_user_customer t
    ON t.link_omni_user_customer_hashkey = s.link_hashkey;
