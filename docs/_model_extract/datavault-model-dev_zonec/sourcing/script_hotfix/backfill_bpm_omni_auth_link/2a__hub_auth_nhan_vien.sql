-- =============================================================================
-- Source : ocb_datavault_prod_sourcing.bpm.auth_nhan_vien
-- Target : hub_auth_nhan_vien
-- BK     : ten_dang_nhap
-- Note   : bpm.auth_nhan_vien khong co data_date → doc toan bo, dedup by etl_time
-- =============================================================================

TRUNCATE TABLE ocb_datavault_prod_cleaned.raw_vault.hub_auth_nhan_vien;

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.hub_auth_nhan_vien
(auth_nhan_vien_hashkey, business_key, source_event_date, load_timestamp, record_source)
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(ten_dang_nhap AS string))), ''), 256) AS auth_nhan_vien_hashkey,
    ten_dang_nhap                                                        AS business_key,
    to_date('20210101', 'yyyyMMdd')                                      AS source_event_date,
    current_timestamp(),
    'bpm__auth_nhan_vien'
FROM ocb_datavault_prod_sourcing.bpm.auth_nhan_vien
WHERE ten_dang_nhap IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY ten_dang_nhap ORDER BY etl_time DESC) = 1;
