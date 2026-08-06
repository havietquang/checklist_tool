-- =============================================================================
-- Source : bpm.khach_hang JOIN bpm.auth_nhan_vien ON nhan_vien_tao = nv.id
-- Target : link_khach_hang_nhan_vien
-- Link key: sha2(kh.id || '$' || nv.ten_dang_nhap, 256)
-- Date   : source_event_date = NGAY_TAO from khach_hang (str+date: yyyy-MM-dd)
-- =============================================================================

TRUNCATE TABLE ocb_datavault_prod_cleaned.raw_vault.link_khach_hang_nhan_vien;

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_khach_hang_nhan_vien
(link_khach_hang_nhan_vien_hashkey, khach_hang_hashkey, auth_nhan_vien_hashkey,
 source_event_date, load_timestamp, record_source)
WITH latest_nv AS (
    SELECT *
    FROM ocb_datavault_prod_sourcing.bpm.auth_nhan_vien
    WHERE ten_dang_nhap IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY etl_time DESC) = 1
),
kh_dedup AS (
    SELECT *
    FROM ocb_datavault_prod_sourcing.bpm.khach_hang
    WHERE id IS NOT NULL AND NGAY_TAO IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id, NGAY_TAO ORDER BY etl_time DESC) = 1
)
SELECT
    sha2(
        COALESCE(UPPER(TRIM(CAST(kh.id            AS string))), '') || '$' ||
        COALESCE(UPPER(TRIM(CAST(nv.ten_dang_nhap AS string))), '')
    , 256)                                                                        AS link_khach_hang_nhan_vien_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(kh.id            AS string))), ''), 256)       AS khach_hang_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(nv.ten_dang_nhap AS string))), ''), 256)       AS auth_nhan_vien_hashkey,
    to_date(kh.NGAY_TAO, 'yyyy-MM-dd')                                           AS source_event_date,
    current_timestamp(),
    'bpm__khach_hang'
FROM kh_dedup kh
INNER JOIN latest_nv nv ON kh.nhan_vien_tao = nv.id
WHERE nv.ten_dang_nhap IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY kh.id, nv.ten_dang_nhap ORDER BY kh.NGAY_TAO) = 1;
