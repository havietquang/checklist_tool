-- =============================================================================
-- DDL + INIT: CREATE OR REPLACE TABLE then MERGE for each ref table
-- Target: ocb_datavault_prod_cleaned.raw_vault
-- =============================================================================

-- =============================================================================
-- BACKFILL: ref_bpm_auth_nhom
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_bpm_auth_nhom
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_bpm_auth_nhom (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    ma_nhom string,
    ten_nhom_viet_tat string COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    ten_nhom_day_du string COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    trang_thai bigint COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    ghi_chu string COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    ocb_hrm_id bigint COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    nhom_cap_tren bigint COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    search_scope bigint COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    nhom_dai_dien bigint COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    cap_phe_duyet bigint COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    quy_trinh bigint COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    cap_do bigint COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    cap_do_tim_kiem bigint COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    cap_do_ecm bigint COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    cap_do_ecm_xlgdtd bigint COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    cap_do_ecm_tsbd bigint COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    json_ecm string COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    ma_nhom_ten string COMMENT 'Truong du lieu tu bang nguon bpm.auth_nhom',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_bpm_auth_nhom
    SELECT
        sha2(('bpm_auth_nhom' || cast(concat_ws('', cast(id as string), cast(ma_nhom as string)) as string)), 256) AS ref_hashkey,
        'bpm_auth_nhom' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(ma_nhom as string)) as string) AS ref_code,
        cast(ma_nhom as string) AS ref_description,
        id,
        ma_nhom,
        ten_nhom_viet_tat,
        ten_nhom_day_du,
        trang_thai,
        ghi_chu,
        ocb_hrm_id,
        nhom_cap_tren,
        search_scope,
        nhom_dai_dien,
        cap_phe_duyet,
        quy_trinh,
        cap_do,
        cap_do_tim_kiem,
        cap_do_ecm,
        cap_do_ecm_xlgdtd,
        cap_do_ecm_tsbd,
        json_ecm,
        ma_nhom_ten,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ten_nhom_viet_tat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ten_nhom_day_du AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(trang_thai AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ghi_chu AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ocb_hrm_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(nhom_cap_tren AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(search_scope AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(nhom_dai_dien AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(cap_phe_duyet AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ma_nhom AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(quy_trinh AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(cap_do AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(cap_do_tim_kiem AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(cap_do_ecm AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(cap_do_ecm_xlgdtd AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(cap_do_ecm_tsbd AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(json_ecm AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ma_nhom_ten AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('bpm__auth_nhom' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.bpm.auth_nhom
    WHERE id IS NOT NULL
      AND ma_nhom IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_bpm_c_danh_muc
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_bpm_c_danh_muc
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_bpm_c_danh_muc (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    ten_danh_muc string COMMENT 'Truong du lieu tu bang nguon bpm.c_danh_muc',
    ghi_chu string COMMENT 'Truong du lieu tu bang nguon bpm.c_danh_muc',
    parent_id bigint COMMENT 'Truong du lieu tu bang nguon bpm.c_danh_muc',
    trang_thai bigint COMMENT 'Truong du lieu tu bang nguon bpm.c_danh_muc',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_bpm_c_danh_muc
    SELECT
        sha2(('bpm_c_danh_muc' || cast(id as string)), 256) AS ref_hashkey,
        'bpm_c_danh_muc' AS ref_type,
        cast(id as string) AS ref_code,
        cast(loai_danh_muc as string) AS ref_description,
        ten_danh_muc,
        ghi_chu,
        parent_id,
        trang_thai,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(loai_danh_muc AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ten_danh_muc AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ghi_chu AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(parent_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(trang_thai AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('bpm__c_danh_muc' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.bpm.c_danh_muc
    WHERE id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_bpm_danh_muc
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_bpm_danh_muc
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_bpm_danh_muc (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    loai bigint,
    ma string COMMENT 'MÃ',
    ten string COMMENT 'Tên',
    ghi_chu string COMMENT 'Ghi chú',
    stt bigint COMMENT 'Truong du lieu tu bang nguon bpm.danh_muc',
    trang_thai bigint COMMENT 'Truong du lieu tu bang nguon bpm.danh_muc',
    nguoi_tao bigint COMMENT 'Truong du lieu tu bang nguon bpm.danh_muc',
    ngay_tao string COMMENT 'Ngày tạo',
    nguoi_update bigint COMMENT 'Truong du lieu tu bang nguon bpm.danh_muc',
    ngay_update string COMMENT 'Ngày cập nhật',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_bpm_danh_muc
    SELECT
        sha2(('bpm_danh_muc' || cast(concat_ws('-', cast(id as string), nvl(cast(loai as string),'')) as string)), 256) AS ref_hashkey,
        'bpm_danh_muc' AS ref_type,
        cast(concat_ws('-', cast(id as string), nvl(cast(loai as string),'')) as string) AS ref_code,
        cast(ma || '-' || ten as string) AS ref_description,
        id,
        loai,
        ma,
        ten,
        ghi_chu,
        stt,
        trang_thai,
        nguoi_tao,
        ngay_tao,
        nguoi_update,
        ngay_update,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ma AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ten AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(loai AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ghi_chu AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(stt AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(trang_thai AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(nguoi_tao AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(nguoi_update AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ngay_update AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('bpm__danh_muc' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.bpm.danh_muc
    WHERE id IS NOT NULL
      AND loai IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_bpm_sk10_san_pham
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_bpm_sk10_san_pham
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_bpm_sk10_san_pham (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    ma_san_pham string,
    ten_san_pham string COMMENT 'Truong du lieu tu bang nguon bpm.sk10_san_pham',
    phan_nhom_san_pham string COMMENT 'Truong du lieu tu bang nguon bpm.sk10_san_pham',
    parent_group string COMMENT 'Truong du lieu tu bang nguon bpm.sk10_san_pham',
    hieu_luc_sp string COMMENT 'Truong du lieu tu bang nguon bpm.sk10_san_pham',
    ghi_chu string COMMENT 'Truong du lieu tu bang nguon bpm.sk10_san_pham',
    category_t24 string COMMENT 'Truong du lieu tu bang nguon bpm.sk10_san_pham',
    loan_support_t24 string COMMENT 'Truong du lieu tu bang nguon bpm.sk10_san_pham',
    dieu_kien_t24 string COMMENT 'Truong du lieu tu bang nguon bpm.sk10_san_pham',
    ngay_tao string COMMENT 'Truong du lieu tu bang nguon bpm.sk10_san_pham',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_bpm_sk10_san_pham
    SELECT
        sha2(('bpm_sk10_san_pham' || cast(concat_ws('', cast(id as string), cast(ma_san_pham as string)) as string)), 256) AS ref_hashkey,
        'bpm_sk10_san_pham' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(ma_san_pham as string)) as string) AS ref_code,
        cast(ma_san_pham as string) AS ref_description,
        id,
        ma_san_pham,
        ten_san_pham,
        phan_nhom_san_pham,
        parent_group,
        hieu_luc_sp,
        ghi_chu,
        category_t24,
        loan_support_t24,
        dieu_kien_t24,
        ngay_tao,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ma_san_pham AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ten_san_pham AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(phan_nhom_san_pham AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(parent_group AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(hieu_luc_sp AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ghi_chu AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(category_t24 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(loan_support_t24 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(dieu_kien_t24 AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('bpm__sk10_san_pham' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.bpm.sk10_san_pham
    WHERE id IS NOT NULL
      AND ma_san_pham IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_crm_contact_result
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_crm_contact_result
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_crm_contact_result (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    status string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_result',
    position string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_result',
    insurance string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_result',
    expired_card_prio string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_result',
    cust_group string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_result',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_crm_contact_result
    SELECT
        sha2(('crm_contact_result' || cast(contact_result_id as string)), 256) AS ref_hashkey,
        'crm_contact_result' AS ref_type,
        cast(contact_result_id as string) AS ref_code,
        cast(contact_result_name as string) AS ref_description,
        status,
        position,
        insurance,
        expired_card_prio,
        cust_group,
        sha2(
            COALESCE(UPPER(TRIM(CAST(contact_result_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(contact_result_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(position AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(insurance AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(expired_card_prio AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(cust_group AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('crm__crm_contact_result' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.crm.crm_contact_result
    WHERE contact_result_id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_crm_contact_status
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_crm_contact_status
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_crm_contact_status (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    status string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_status',
    position string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_status',
    kh_denhan_bh string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_status',
    kh_cosp_dexuat string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_status',
    kh_roibo string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_status',
    hd_tiengui_denhan string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_status',
    sn_khachhang string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_status',
    kh_hienhuu string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_status',
    taikichhoat string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_status',
    kh_expiredcard string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_status',
    chbh_ganden string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_status',
    cust_group string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_status',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_crm_contact_status
    SELECT
        sha2(('crm_contact_status' || cast(contact_status_id as string)), 256) AS ref_hashkey,
        'crm_contact_status' AS ref_type,
        cast(contact_status_id as string) AS ref_code,
        cast(contact_status_name as string) AS ref_description,
        status,
        position,
        kh_denhan_bh,
        kh_cosp_dexuat,
        kh_roibo,
        hd_tiengui_denhan,
        sn_khachhang,
        kh_hienhuu,
        taikichhoat,
        kh_expiredcard,
        chbh_ganden,
        cust_group,
        sha2(
            COALESCE(UPPER(TRIM(CAST(contact_status_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(contact_status_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(position AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(kh_denhan_bh AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(kh_cosp_dexuat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(kh_roibo AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(hd_tiengui_denhan AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(sn_khachhang AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(kh_hienhuu AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(taikichhoat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(kh_expiredcard AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(chbh_ganden AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(cust_group AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('crm__crm_contact_status' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.crm.crm_contact_status
    WHERE contact_status_id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_crm_contact_type
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_crm_contact_type
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_crm_contact_type (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    status string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_type',
    position string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_type',
    kh_denhan_bh string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_type',
    kh_cosp_dexuat string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_type',
    kh_roibo string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_type',
    hd_tiengui_denhan string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_type',
    sn_khachhang string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_type',
    kh_hienhuu string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_type',
    taikichhoat string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_type',
    kh_expiredcard string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_type',
    chbh_ganden string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_type',
    cust_group string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_type',
    iscall string COMMENT 'Truong du lieu tu bang nguon crm.crm_contact_type',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_crm_contact_type
    SELECT
        sha2(('crm_contact_type' || cast(contact_type_id as string)), 256) AS ref_hashkey,
        'crm_contact_type' AS ref_type,
        cast(contact_type_id as string) AS ref_code,
        cast(contact_type_name as string) AS ref_description,
        status,
        position,
        kh_denhan_bh,
        kh_cosp_dexuat,
        kh_roibo,
        hd_tiengui_denhan,
        sn_khachhang,
        kh_hienhuu,
        taikichhoat,
        kh_expiredcard,
        chbh_ganden,
        cust_group,
        iscall,
        sha2(
            COALESCE(UPPER(TRIM(CAST(contact_type_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(contact_type_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(position AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(kh_denhan_bh AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(kh_cosp_dexuat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(kh_roibo AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(hd_tiengui_denhan AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(sn_khachhang AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(kh_hienhuu AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(taikichhoat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(kh_expiredcard AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(chbh_ganden AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(cust_group AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(iscall AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('crm__crm_contact_type' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.crm.crm_contact_type
    WHERE contact_type_id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_crm_custgroup
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_crm_custgroup
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_crm_custgroup (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    parent_key string COMMENT 'Truong du lieu tu bang nguon crm.crm_naming_custgroup',
    user_created string COMMENT 'Truong du lieu tu bang nguon crm.crm_naming_custgroup',
    date_created date COMMENT 'Truong du lieu tu bang nguon crm.crm_naming_custgroup',
    user_updated string COMMENT 'Truong du lieu tu bang nguon crm.crm_naming_custgroup',
    date_updated date COMMENT 'Truong du lieu tu bang nguon crm.crm_naming_custgroup',
    user_deleted string COMMENT 'Truong du lieu tu bang nguon crm.crm_naming_custgroup',
    date_deleted date COMMENT 'Truong du lieu tu bang nguon crm.crm_naming_custgroup',
    isactive string COMMENT 'Truong du lieu tu bang nguon crm.crm_naming_custgroup',
    isdeleted string COMMENT 'Truong du lieu tu bang nguon crm.crm_naming_custgroup',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_crm_custgroup
    SELECT
        sha2(('crm_custgroup' || cast(custgroup as string)), 256) AS ref_hashkey,
        'crm_custgroup' AS ref_type,
        cast(custgroup as string) AS ref_code,
        cast(name as string) AS ref_description,
        parent_key,
        user_created,
        date_created,
        user_updated,
        date_updated,
        user_deleted,
        date_deleted,
        isactive,
        isdeleted,
        sha2(
            COALESCE(UPPER(TRIM(CAST(custgroup AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(user_created AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(date_created AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(user_updated AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(date_updated AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(user_deleted AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(date_deleted AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(isactive AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(isdeleted AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(parent_key AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('crm__crm_naming_custgroup' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.crm.crm_naming_custgroup
    WHERE custgroup IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_omni_fee_discount
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_omni_fee_discount
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_omni_fee_discount (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id string,
    code string,
    created_at string COMMENT 'Truong du lieu tu bang nguon omni.fee_discount',
    created_by string COMMENT 'Truong du lieu tu bang nguon omni.fee_discount',
    updated_at string COMMENT 'Truong du lieu tu bang nguon omni.fee_discount',
    updated_by string COMMENT 'Truong du lieu tu bang nguon omni.fee_discount',
    discount_rate decimal(19,2) COMMENT 'Truong du lieu tu bang nguon omni.fee_discount',
    end_at string COMMENT 'Truong du lieu tu bang nguon omni.fee_discount',
    name string COMMENT 'Truong du lieu tu bang nguon omni.fee_discount',
    start_at string COMMENT 'Truong du lieu tu bang nguon omni.fee_discount',
    status string COMMENT 'Truong du lieu tu bang nguon omni.fee_discount',
    fee_discount_type string COMMENT 'Truong du lieu tu bang nguon omni.fee_discount',
    fee_reduction_time int COMMENT 'Truong du lieu tu bang nguon omni.fee_discount',
    approved_by string COMMENT 'Truong du lieu tu bang nguon omni.fee_discount',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_omni_fee_discount
    SELECT
        sha2(('omni_fee_discount' || cast(concat_ws('', cast(id as string), cast(code as string)) as string)), 256) AS ref_hashkey,
        'omni_fee_discount' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(code as string)) as string) AS ref_code,
        cast(description as string) AS ref_description,
        id,
        code,
        created_at,
        created_by,
        updated_at,
        updated_by,
        discount_rate,
        end_at,
        name,
        start_at,
        status,
        fee_discount_type,
        fee_reduction_time,
        approved_by,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(created_by AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(updated_by AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(discount_rate AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(end_at AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(start_at AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(fee_discount_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(fee_reduction_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(approved_by AS string))), ''),
            256
        ) AS hashdiff,
        try_to_date(least(updated_at, created_at)) AS source_event_date,
        cast('omni__fee_discount' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.omni.fee_discount
    WHERE try_to_date(least(updated_at, created_at)) BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
      AND code IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_omni_master_data
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_omni_master_data
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_omni_master_data (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id string,
    code string,
    created_at string COMMENT 'Truong du lieu tu bang nguon omni.master_data',
    created_by string COMMENT 'Truong du lieu tu bang nguon omni.master_data',
    updated_at string COMMENT 'Truong du lieu tu bang nguon omni.master_data',
    updated_by string COMMENT 'Truong du lieu tu bang nguon omni.master_data',
    name string COMMENT 'Truong du lieu tu bang nguon omni.master_data',
    status string COMMENT 'Truong du lieu tu bang nguon omni.master_data',
    type string COMMENT 'Truong du lieu tu bang nguon omni.master_data',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_omni_master_data
    SELECT
        sha2(('omni_master_data' || cast(concat_ws('', cast(id as string), cast(code as string)) as string)), 256) AS ref_hashkey,
        'omni_master_data' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(code as string)) as string) AS ref_code,
        cast(description as string) AS ref_description,
        id,
        code,
        created_at,
        created_by,
        updated_at,
        updated_by,
        name,
        status,
        type,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(created_by AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(updated_by AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(type AS string))), ''),
            256
        ) AS hashdiff,
        try_to_date(least(updated_at, created_at)) AS source_event_date,
        cast('omni__master_data' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.omni.master_data
    WHERE try_to_date(least(updated_at, created_at)) BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
      AND code IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_omni_package
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_omni_package
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_omni_package (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id string,
    code string,
    created_at string COMMENT 'Truong du lieu tu bang nguon omni.package',
    created_by string COMMENT 'Truong du lieu tu bang nguon omni.package',
    updated_at string COMMENT 'Truong du lieu tu bang nguon omni.package',
    updated_by string COMMENT 'Truong du lieu tu bang nguon omni.package',
    description string COMMENT 'Truong du lieu tu bang nguon omni.package',
    status string COMMENT 'Truong du lieu tu bang nguon omni.package',
    can_register_ep_portal tinyint COMMENT 'Truong du lieu tu bang nguon omni.package',
    effective_date date COMMENT 'Truong du lieu tu bang nguon omni.package',
    package_discontinuation_date date COMMENT 'Truong du lieu tu bang nguon omni.package',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_omni_package
    SELECT
        sha2(('omni_package' || cast(concat_ws('', cast(id as string), cast(code as string)) as string)), 256) AS ref_hashkey,
        'omni_package' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(code as string)) as string) AS ref_code,
        cast(name as string) AS ref_description,
        id,
        code,
        created_at,
        created_by,
        updated_at,
        updated_by,
        description,
        status,
        can_register_ep_portal,
        effective_date,
        package_discontinuation_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(created_by AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(updated_by AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(can_register_ep_portal AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(package_discontinuation_date AS string))), ''),
            256
        ) AS hashdiff,
        try_to_date(least(updated_at, created_at)) AS source_event_date,
        cast('omni__package' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.omni.package
    WHERE try_to_date(least(updated_at, created_at)) BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
      AND code IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_omni_service_provider
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_omni_service_provider
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_omni_service_provider (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    provider_code string,
    provider_icon string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    services_id bigint COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    service_code string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    provider_group_code string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    provider_group_name string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    auto_bill string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    title string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    image string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    created_at string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    modified_at string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    created_by string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    modified_by string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    provider_group_service_id bigint COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    prop1 string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    prop2 string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    prop3 decimal(19,2) COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    prop4 bigint COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    prop5 string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    gateway_id string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    visible int COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    allow_credit_card int COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    content_en string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    content_vi string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    content_reason string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    provider_order bigint COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    save_my_bill string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    module string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    group_service string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    has_fee int COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    allow_in_group int COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    allow_fav_trans int COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    alt_provider_code string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    alt_gateway_id string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    content_ko string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    content_ja string COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    auto_bill_permission tinyint COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    manual_bill_permission tinyint COMMENT 'Truong du lieu tu bang nguon omni.service_provider',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_omni_service_provider
    SELECT
        sha2(('omni_service_provider' || cast(concat_ws('', cast(id as string), cast(provider_code as string)) as string)), 256) AS ref_hashkey,
        'omni_service_provider' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(provider_code as string)) as string) AS ref_code,
        cast(provider_name as string) AS ref_description,
        id,
        provider_code,
        provider_icon,
        services_id,
        service_code,
        provider_group_code,
        provider_group_name,
        auto_bill,
        title,
        image,
        created_at,
        modified_at,
        created_by,
        modified_by,
        provider_group_service_id,
        prop1,
        prop2,
        prop3,
        prop4,
        prop5,
        gateway_id,
        visible,
        allow_credit_card,
        content_en,
        content_vi,
        content_reason,
        provider_order,
        save_my_bill,
        module,
        group_service,
        has_fee,
        allow_in_group,
        allow_fav_trans,
        alt_provider_code,
        alt_gateway_id,
        content_ko,
        content_ja,
        auto_bill_permission,
        manual_bill_permission,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(provider_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(provider_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(provider_icon AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(services_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(service_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(provider_group_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(provider_group_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(auto_bill AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(title AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(image AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(created_by AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(modified_by AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(provider_group_service_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(prop1 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(prop2 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(prop3 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(prop4 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(prop5 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(gateway_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(visible AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(allow_credit_card AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(content_en AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(content_vi AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(content_reason AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(provider_order AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(save_my_bill AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(module AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(group_service AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(has_fee AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(allow_in_group AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(allow_fav_trans AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(alt_provider_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(alt_gateway_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(content_ko AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(content_ja AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(auto_bill_permission AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(manual_bill_permission AS string))), ''),
            256
        ) AS hashdiff,
        try_to_date(least(modified_at, created_at)) AS source_event_date,
        cast('omni__service_provider' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.omni.service_provider
    WHERE try_to_date(least(modified_at, created_at)) BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
      AND provider_code IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_omni_service_type
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_omni_service_type
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_omni_service_type (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id string,
    service_code string,
    business_function_id string COMMENT 'Truong du lieu tu bang nguon omni.service_type',
    maximum_default_transaction_bound decimal(19,2) COMMENT 'Truong du lieu tu bang nguon omni.service_type',
    minimum_default_transaction_bound decimal(19,2) COMMENT 'Truong du lieu tu bang nguon omni.service_type',
    support_limit tinyint COMMENT 'Truong du lieu tu bang nguon omni.service_type',
    payment_type string COMMENT 'Truong du lieu tu bang nguon omni.service_type',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_omni_service_type
    SELECT
        sha2(('omni_service_type' || cast(concat_ws('', cast(id as string), cast(service_code as string)) as string)), 256) AS ref_hashkey,
        'omni_service_type' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(service_code as string)) as string) AS ref_code,
        cast(service_name as string) AS ref_description,
        id,
        service_code,
        business_function_id,
        maximum_default_transaction_bound,
        minimum_default_transaction_bound,
        support_limit,
        payment_type,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(business_function_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(maximum_default_transaction_bound AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(minimum_default_transaction_bound AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(service_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(service_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(support_limit AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(payment_type AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('omni__service_type' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.omni.service_type
    WHERE id IS NOT NULL
      AND service_code IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_omni_services
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_omni_services
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_omni_services (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    service_code string,
    service_icon string COMMENT 'Truong du lieu tu bang nguon omni.services',
    created_at string COMMENT 'Truong du lieu tu bang nguon omni.services',
    modified_at string COMMENT 'Truong du lieu tu bang nguon omni.services',
    created_by string COMMENT 'Truong du lieu tu bang nguon omni.services',
    modified_by string COMMENT 'Truong du lieu tu bang nguon omni.services',
    prop1 string COMMENT 'Truong du lieu tu bang nguon omni.services',
    prop2 string COMMENT 'Truong du lieu tu bang nguon omni.services',
    prop3 decimal(19,2) COMMENT 'Truong du lieu tu bang nguon omni.services',
    prop4 bigint COMMENT 'Truong du lieu tu bang nguon omni.services',
    prop5 string COMMENT 'Truong du lieu tu bang nguon omni.services',
    service_order int COMMENT 'Truong du lieu tu bang nguon omni.services',
    service_code_new string COMMENT 'Truong du lieu tu bang nguon omni.services',
    visible int COMMENT 'Truong du lieu tu bang nguon omni.services',
    group_service string COMMENT 'Truong du lieu tu bang nguon omni.services',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_omni_services
    SELECT
        sha2(('omni_services' || cast(concat_ws('', cast(id as string), cast(service_code as string)) as string)), 256) AS ref_hashkey,
        'omni_services' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(service_code as string)) as string) AS ref_code,
        cast(service_name as string) AS ref_description,
        id,
        service_code,
        service_icon,
        created_at,
        modified_at,
        created_by,
        modified_by,
        prop1,
        prop2,
        prop3,
        prop4,
        prop5,
        service_order,
        service_code_new,
        visible,
        group_service,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(service_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(service_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(service_icon AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(created_by AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(modified_by AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(prop1 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(prop2 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(prop3 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(prop4 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(prop5 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(service_order AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(service_code_new AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(visible AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(group_service AS string))), ''),
            256
        ) AS hashdiff,
        try_to_date(least(modified_at, created_at)) AS source_event_date,
        cast('omni__services' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.omni.services
    WHERE try_to_date(least(modified_at, created_at)) BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
      AND service_code IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_acct_gen_condition
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_acct_gen_condition
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_acct_gen_condition (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_item string COMMENT 'Trường điều kiện ưu tiên',
    t_priority string COMMENT 'Mức độ ưu tiên',
    t_value string COMMENT 'Giá trị thực tế theo ITEM',
    t_multivalue string COMMENT 'Khai báo cum đa giá trị tiếp theo hay không',
    t_co_code string COMMENT 'Mã CN quản lý',
    t_inputter string COMMENT 'User nhập',
    t_date_time string COMMENT 'Ngày thực hiện',
    t_authoriser string COMMENT 'User duyệt',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_acct_gen_condition
    SELECT
        sha2(('acct_gen_condition' || cast(id as string)), 256) AS ref_hashkey,
        'acct_gen_condition' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_item,
        t_priority,
        t_value,
        t_multivalue,
        t_co_code,
        t_inputter,
        t_date_time,
        t_authoriser,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_item AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_priority AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_value AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_multivalue AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_acct_gen_condition' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_acct_gen_condition
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_auto_name
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_auto_name
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_auto_name (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_auto_name
    SELECT
        sha2(('auto_name' || cast(id as string)), 256) AS ref_hashkey,
        'auto_name' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_name as string) AS ref_description,
        data_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_name AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_auto_name' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_auto_name
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_az_product_parameter
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_az_product_parameter
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_az_product_parameter (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_allowed_categ bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_az_product_parameter',
    t_dr_txn_code bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_az_product_parameter',
    t_cr_txn_code bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_az_product_parameter',
    t_int_basis string COMMENT 'Cơ số tính lãi',
    t_minimum_term string COMMENT 'Số tiền gửi tối thiểu',
    t_maximum_term string COMMENT 'Số tiền gửi tối đa',
    t_periodic_rate_key string COMMENT 'Key lãi suất',
    t_maturity_instr string COMMENT 'Hình thức tái tục',
    t_record_status string COMMENT 'Trạng thái bản ghi',
    t_curr_no bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_az_product_parameter',
    t_inputter string COMMENT 'User nhập',
    t_authoriser string COMMENT 'User duyệt',
    t_date_time string COMMENT 'Ngày thực hiện',
    t_co_code string COMMENT 'Mã Chi nhánh',
    t_loan_deposit string COMMENT 'Loại tiền gửi/tiền vay',
    t_prod_end_date string COMMENT 'Ngày bắt đầu',
    t_prod_start_date string COMMENT 'Ngày kết thúc',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_az_product_parameter
    SELECT
        sha2(('az_product_parameter' || cast(id as string)), 256) AS ref_hashkey,
        'az_product_parameter' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_allowed_categ,
        t_dr_txn_code,
        t_cr_txn_code,
        t_int_basis,
        t_minimum_term,
        t_maximum_term,
        t_periodic_rate_key,
        t_maturity_instr,
        t_record_status,
        t_curr_no,
        t_inputter,
        t_authoriser,
        t_date_time,
        t_co_code,
        t_loan_deposit,
        t_prod_end_date,
        t_prod_start_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_allowed_categ AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_dr_txn_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_cr_txn_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_int_basis AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_minimum_term AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_maximum_term AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_periodic_rate_key AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_maturity_instr AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_loan_deposit AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_prod_end_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_prod_start_date AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_az_product_parameter' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_az_product_parameter
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_basic_interest
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_basic_interest
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_basic_interest (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_interest_rate decimal(38,10) COMMENT 'Lãi suất',
    t_record_status string COMMENT 'Trạng thái',
    t_curr_no bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_basic_interest',
    t_inputter string COMMENT 'Người nhập',
    t_authoriser string COMMENT 'Người duyệt',
    t_date_time string COMMENT 'Ngày giờ duyệt',
    t_co_code string COMMENT 'Mã chi nhánh',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_basic_interest
    SELECT
        sha2(('basic_interest' || cast(id as string)), 256) AS ref_hashkey,
        'basic_interest' AS ref_type,
        cast(id as string) AS ref_code,
        cast(id as string) AS ref_description,
        data_date,
        t_interest_rate,
        t_record_status,
        t_curr_no,
        t_inputter,
        t_authoriser,
        t_date_time,
        t_co_code,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_interest_rate AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_basic_interest' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_basic_interest
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_bc_sort_code
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_bc_sort_code
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_bc_sort_code (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_telephone_no string COMMENT 'Kênh tham gia CITAD/VCB/BIDV',
    t_identity_kind string COMMENT 'Mã trực tiếp/gián tiếp áp dụng đi CITAD',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_bc_sort_code
    SELECT
        sha2(('bc_sort_code' || cast(id as string)), 256) AS ref_hashkey,
        'bc_sort_code' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_name as string) AS ref_description,
        data_date,
        t_telephone_no,
        t_identity_kind,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_telephone_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_identity_kind AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_bc_sort_code' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_bc_sort_code
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_bosc_comp_reg
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_bosc_comp_reg
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_bosc_comp_reg (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'không dùng',
    t_account_number string COMMENT 'không dùng',
    t_branch_id string COMMENT 'không dùng',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_bosc_comp_reg
    SELECT
        sha2(('bosc_comp_reg' || cast(id as string)), 256) AS ref_hashkey,
        'bosc_comp_reg' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_company_name as string) AS ref_description,
        data_date,
        t_account_number,
        t_branch_id,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_account_number AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_branch_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_company_name AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_bosc_comp_reg' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_bosc_comp_reg
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_category
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_category
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_category (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_short_name string COMMENT 'Tên phân loại viết tắt',
    t_product string COMMENT 'Không dùng',
    t_prod_id bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_category',
    t_co_vat string COMMENT 'Không dùng',
    t_type_business string COMMENT 'Không dùng',
    t_is_mand string COMMENT 'Không dùng',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_category
    SELECT
        sha2(('category' || cast(id as string)), 256) AS ref_hashkey,
        'category' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_short_name,
        t_product,
        t_prod_id,
        t_co_vat,
        t_type_business,
        t_is_mand,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_short_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_product AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_prod_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_vat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_type_business AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_is_mand AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_category' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_category
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_collateral_code
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_collateral_code
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_collateral_code (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_collateral_code bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_collateral_code',
    t_short_name string COMMENT 'Truong du lieu tu bang nguon t24.t24_collateral_code',
    t_collateral_type string COMMENT 'Phân loại TSĐB',
    t_record_status string COMMENT 'Trạng thái',
    t_curr_no bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_collateral_code',
    t_inputter string COMMENT 'Người nhập',
    t_authoriser string COMMENT 'Người duyệt',
    t_date_time string COMMENT 'Ngày nhập',
    t_co_code string COMMENT 'Mã chi nhánh',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_collateral_code
    SELECT
        sha2(('collateral_code' || cast(id as string)), 256) AS ref_hashkey,
        'collateral_code' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_collateral_code,
        t_short_name,
        t_collateral_type,
        t_record_status,
        t_curr_no,
        t_inputter,
        t_authoriser,
        t_date_time,
        t_co_code,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_collateral_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_short_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_collateral_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_collateral_code' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_collateral_code
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_collateral_type
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_collateral_type
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_collateral_type (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_collateral_type bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_collateral_type',
    t_application string COMMENT 'Module áp dụng',
    t_application_input string COMMENT 'Tham số nhập trường Application_ID trong TSĐB(( M: bắt buộc/O không bắt buộc/N: không được nhập)',
    t_nominal_value string COMMENT 'Tham số giá trị định giá( M: bắt buộc/O không bắt buộc)',
    t_execution_value string COMMENT 'Tham số giá trị định giá( M: bắt buộc/O không bắt buộc)',
    t_gen_ledger_value string COMMENT 'Qui  định của Giá trị  Ghi sổ = X% của giá trị định giá',
    t_central_bank_value string COMMENT 'Qui  định của Giá trị  b.cáo NHNN = X% của giá trị định giá',
    t_third_party_value string COMMENT 'Tham số giá trị định giá( M: bắt buộc/O không bắt buộc)',
    t_record_status string COMMENT 'Trạng thái record',
    t_curr_no bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_collateral_type',
    t_inputter string COMMENT 'Người nhập',
    t_authoriser string COMMENT 'Người duyệt',
    t_date_time string COMMENT 'Ngày nhập',
    t_co_code string COMMENT 'Mã chi nhánh',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_collateral_type
    SELECT
        sha2(('collateral_type' || cast(id as string)), 256) AS ref_hashkey,
        'collateral_type' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_collateral_type,
        t_application,
        t_application_input,
        t_nominal_value,
        t_execution_value,
        t_gen_ledger_value,
        t_central_bank_value,
        t_third_party_value,
        t_record_status,
        t_curr_no,
        t_inputter,
        t_authoriser,
        t_date_time,
        t_co_code,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_collateral_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_application AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_application_input AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_nominal_value AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_execution_value AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_gen_ledger_value AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_central_bank_value AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_third_party_value AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_collateral_type' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_collateral_type
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_company
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_company
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_company (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày báo cáo',
    t_mnemonic string COMMENT 'Tên tắt',
    t_consolidation_mark string COMMENT 'Không dùng',
    t_default_no_of_auth string COMMENT 'Không dùng',
    t_pgm_autom_id string COMMENT 'Không dùng',
    t_applications string COMMENT 'Không dùng',
    t_tax_code string COMMENT 'Không dùng',
    t_financial_year_end string COMMENT 'Không dùng',
    t_sub_division_code string COMMENT 'Không dùng',
    t_official_holiday string COMMENT 'Không dùng',
    t_branch_holiday string COMMENT 'Không dùng',
    t_batch_holiday string COMMENT 'Không dùng',
    t_name_address string COMMENT 'Không dùng',
    t_language_code string COMMENT 'Không dùng',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_company
    SELECT
        sha2(('company' || cast(id as string)), 256) AS ref_hashkey,
        'company' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_company_name as string) AS ref_description,
        data_date,
        t_mnemonic,
        t_consolidation_mark,
        t_default_no_of_auth,
        t_pgm_autom_id,
        t_applications,
        t_tax_code,
        t_financial_year_end,
        t_sub_division_code,
        t_official_holiday,
        t_branch_holiday,
        t_batch_holiday,
        t_name_address,
        t_language_code,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_mnemonic AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_company_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_consolidation_mark AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_default_no_of_auth AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_pgm_autom_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_applications AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_tax_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_financial_year_end AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_sub_division_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_official_holiday AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_branch_holiday AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_batch_holiday AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_name_address AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_language_code AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_company' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_company
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_country
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_country
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_country (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_short_name string COMMENT 'Tên quốc gia viết tắt',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_country
    SELECT
        sha2(('country' || cast(id as string)), 256) AS ref_hashkey,
        'country' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_country_name as string) AS ref_description,
        data_date,
        t_short_name,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_country_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_short_name AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_country' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_country
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_de_bic
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_de_bic
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_de_bic (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_city string COMMENT 'Không dùng',
    t_address string COMMENT 'Địa chỉ',
    t_country string COMMENT 'Quốc gia',
    t_subtype_ind string COMMENT 'Không dùng',
    t_recordkey string COMMENT 'Trường hệ thống -- mặc định theo @ID',
    t_branch string COMMENT 'Không dùng',
    t_bic_code string COMMENT 'Không dùng',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_de_bic
    SELECT
        sha2(('de_bic' || cast(id as string)), 256) AS ref_hashkey,
        'de_bic' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_institution as string) AS ref_description,
        data_date,
        t_city,
        t_address,
        t_country,
        t_subtype_ind,
        t_recordkey,
        t_branch,
        t_bic_code,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_institution AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_city AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_address AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_country AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_subtype_ind AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_recordkey AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_branch AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_bic_code AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_de_bic' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_de_bic
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_dealer_desk
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_dealer_desk
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_dealer_desk (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_dealer_desk
    SELECT
        sha2(('dealer_desk' || cast(id as string)), 256) AS ref_hashkey,
        'dealer_desk' AS ref_type,
        cast(id as string) AS ref_code,
        cast(descriptions as string) AS ref_description,
        data_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(descriptions AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_dealer_desk' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_dealer_desk
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_department
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_department
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_department (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Không dùng',
    t_group_id string COMMENT 'Không dùng',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_department
    SELECT
        sha2(('department' || cast(id as string)), 256) AS ref_hashkey,
        'department' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_group_id,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_group_id AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_department' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_department
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ft_txn_type_condition
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ft_txn_type_condition
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ft_txn_type_condition (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_txn_code_cr string COMMENT 'Txn Code Cr',
    t_txn_code_dr string COMMENT 'Txn Code Dr',
    t_sto_txn_code_cr string COMMENT 'Sto Txn Code Cr',
    t_sto_txn_code_dr string COMMENT 'Sto Txn Code Dr',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ft_txn_type_condition
    SELECT
        sha2(('ft_txn_type_condition' || cast(id as string)), 256) AS ref_hashkey,
        'ft_txn_type_condition' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_short_descr as string) AS ref_description,
        data_date,
        t_txn_code_cr,
        t_txn_code_dr,
        t_sto_txn_code_cr,
        t_sto_txn_code_dr,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_short_descr AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_txn_code_cr AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_txn_code_dr AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_sto_txn_code_cr AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_sto_txn_code_dr AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ft_txn_type_condition' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ft_txn_type_condition
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_industry
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_industry
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_industry (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_sbv_industry string COMMENT 'Mã ngành kinh tế báo cáo NHNN',
    t_sub_industry bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_industry',
    t_active string COMMENT 'Tình trạng sử dụng',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_industry
    SELECT
        sha2(('industry' || cast(id as string)), 256) AS ref_hashkey,
        'industry' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_sbv_industry,
        t_sub_industry,
        t_active,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_sbv_industry AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_sub_industry AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_active AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_industry' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_industry
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_int_chg_type
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_int_chg_type
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_int_chg_type (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_int_chg_type
    SELECT
        sha2(('int_chg_type' || cast(t_frequency as string)), 256) AS ref_hashkey,
        'int_chg_type' AS ref_type,
        cast(t_frequency as string) AS ref_code,
        cast(t_descriptions as string) AS ref_description,
        data_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_descriptions AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_frequency AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_int_chg_type' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_int_chg_type
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_job_title
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_job_title
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_job_title (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_job_title
    SELECT
        sha2(('job_title' || cast(id as string)), 256) AS ref_hashkey,
        'job_title' AS ref_type,
        cast(id as string) AS ref_code,
        cast(description as string) AS ref_description,
        data_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(description AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_job_title' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_job_title
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_lc_types
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_lc_types
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_lc_types (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_category_code bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_lc_types',
    t_import_export string COMMENT 'Loại LC ( Import/Export/...)',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_lc_types
    SELECT
        sha2(('lc_types' || cast(id as string)), 256) AS ref_hashkey,
        'lc_types' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_category_code,
        t_import_export,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_category_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_import_export AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_lc_types' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_lc_types
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ld_aprv_user
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ld_aprv_user
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ld_aprv_user (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_ubtd1 string COMMENT 'Ủy ban tín dụng 1( None/Yes/No)',
    t_ubtd2 string COMMENT 'Ủy ban tín dụng 2( None/Yes/No)',
    t_ubtd3 string COMMENT 'Ủy ban tín dụng 3( None/Yes/No)',
    t_direct_aprv string COMMENT 'Cấp phê duyệt trực tiếp( None/Yes/No)',
    t_indirect_aprv string COMMENT 'Cấp phê duyệt gián tiếp ( None/Yes/No)',
    t_reval_level string COMMENT 'Cấp tái thẩm định (( None/Yes/No)',
    t_active_info string COMMENT 'Có hiệu lực ( None/Yes/No)',
    t_user_status string COMMENT 'Tình trạng làm việc(None/Work/Off/ChangeDept)',
    t_curr_no string COMMENT 'số thay đổi trạng thái của record',
    t_inputter string COMMENT 'Người nhập',
    t_authoriser string COMMENT 'người duyệt',
    t_date_time string COMMENT 'Ngày nhập',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ld_aprv_user
    SELECT
        sha2(('ld_aprv_user' || cast(id as string)), 256) AS ref_hashkey,
        'ld_aprv_user' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_app_user_name as string) AS ref_description,
        data_date,
        t_ubtd1,
        t_ubtd2,
        t_ubtd3,
        t_direct_aprv,
        t_indirect_aprv,
        t_reval_level,
        t_active_info,
        t_user_status,
        t_curr_no,
        t_inputter,
        t_authoriser,
        t_date_time,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_app_user_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ubtd1 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ubtd2 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ubtd3 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_direct_aprv AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_indirect_aprv AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_reval_level AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_active_info AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_user_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ld_aprv_user' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ld_aprv_user
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ld_economic_sector
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ld_economic_sector
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ld_economic_sector (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_parent_id string COMMENT 'Truong du lieu tu bang nguon t24.t24_ld_economic_sector',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ld_economic_sector
    SELECT
        sha2(('ld_economic_sector' || cast(id as string)), 256) AS ref_hashkey,
        'ld_economic_sector' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_parent_id,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_parent_id AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ld_economic_sector' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ld_economic_sector
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ld_ins_type_comp
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ld_ins_type_comp
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ld_ins_type_comp (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_ins_type string COMMENT 'Loại bảo hiểm( NOne/No/Yes)',
    t_ins_company string COMMENT 'Công ty bảo hiẻm(None/No/Yes)',
    t_ins_type_id string COMMENT 'Mã loại cty bảo hiểm',
    t_nused string COMMENT 'Đánh dấ không còn hiêu lực',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ld_ins_type_comp
    SELECT
        sha2(('ld_ins_type_comp' || cast(id as string)), 256) AS ref_hashkey,
        'ld_ins_type_comp' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_ins_type,
        t_ins_company,
        t_ins_type_id,
        t_nused,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ins_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ins_company AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ins_type_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_nused AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ld_ins_type_comp' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ld_ins_type_comp
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ld_partner
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ld_partner
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ld_partner (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_record_status string COMMENT 'Truong du lieu tu bang nguon t24.t24_ld_partner',
    t_curr_no bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_ld_partner',
    t_inputter string COMMENT 'người nhập',
    t_date_time string COMMENT 'ngày nhập',
    t_authoriser string COMMENT 'người duyệt',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ld_partner
    SELECT
        sha2(('ld_partner' || cast(id as string)), 256) AS ref_hashkey,
        'ld_partner' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_name as string) AS ref_description,
        data_date,
        t_record_status,
        t_curr_no,
        t_inputter,
        t_date_time,
        t_authoriser,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ld_partner' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ld_partner
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ld_promotion
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ld_promotion
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ld_promotion (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_record_status string COMMENT 'trrạng thái của recrod',
    t_curr_no bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_ld_promotion',
    t_inputter string COMMENT 'người nhập',
    t_date_time string COMMENT 'ngày nhập',
    t_authoriser string COMMENT 'người duyệt',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ld_promotion
    SELECT
        sha2(('ld_promotion' || cast(id as string)), 256) AS ref_hashkey,
        'ld_promotion' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_record_status,
        t_curr_no,
        t_inputter,
        t_date_time,
        t_authoriser,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ld_promotion' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ld_promotion
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_limit_level_auth
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_limit_level_auth
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_limit_level_auth (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_limit_level_auth
    SELECT
        sha2(('limit_level_auth' || cast(id as string)), 256) AS ref_hashkey,
        'limit_level_auth' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_limit_amount as string) AS ref_description,
        data_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_limit_amount AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_limit_level_auth' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_limit_level_auth
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_limit_reference
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_limit_reference
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_limit_reference (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_limit_reference bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_limit_reference',
    t_short_name string COMMENT 'Truong du lieu tu bang nguon t24.t24_limit_reference',
    t_reducing_limit string COMMENT 'Giới hạn hạn mức (Yes/No)',
    t_reference_child string COMMENT 'sản phẩm vay liên kết hạn mức',
    t_record_status string COMMENT 'trạng thái record',
    t_curr_no bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_limit_reference',
    t_inputter string COMMENT 'người duyệt',
    t_authoriser string COMMENT 'người nhập',
    t_date_time string COMMENT 'người duyệt',
    t_co_code string COMMENT 'mã chi nhánh',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_limit_reference
    SELECT
        sha2(('limit_reference' || cast(id as string)), 256) AS ref_hashkey,
        'limit_reference' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_limit_reference,
        t_short_name,
        t_reducing_limit,
        t_reference_child,
        t_record_status,
        t_curr_no,
        t_inputter,
        t_authoriser,
        t_date_time,
        t_co_code,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_limit_reference AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_short_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_reducing_limit AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_reference_child AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_limit_reference' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_limit_reference
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_loan_method
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_loan_method
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_loan_method (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_loan_method string COMMENT 'Không dùng',
    t_record_status string COMMENT 'Tình trạng',
    t_curr_no bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_loan_method',
    t_inputter string COMMENT 'Người nhập',
    t_authoriser string COMMENT 'Người duyệt',
    t_date_time string COMMENT 'Ngày giờ thay đổi',
    t_co_code string COMMENT 'Chi nhánh',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_loan_method
    SELECT
        sha2(('loan_method' || cast(id as string)), 256) AS ref_hashkey,
        'loan_method' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_loan_method,
        t_record_status,
        t_curr_no,
        t_inputter,
        t_authoriser,
        t_date_time,
        t_co_code,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_loan_method AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_loan_method' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_loan_method
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_loan_purpose
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_loan_purpose
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_loan_purpose (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_level_1 bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_loan_purpose',
    t_level_1_desc string COMMENT 'Tên cấp 1',
    t_level_2 bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_loan_purpose',
    t_level_2_desc string COMMENT 'Tên cấp 2',
    t_record_status string COMMENT 'Tình trạng',
    t_curr_no bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_loan_purpose',
    t_inputter string COMMENT 'Người nhập',
    t_authoriser string COMMENT 'Người duyệt',
    t_date_time string COMMENT 'Ngày giờ thay đổi',
    t_co_code string COMMENT 'Chi nhánh',
    t_category string COMMENT 'Truong du lieu tu bang nguon t24.t24_loan_purpose',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_loan_purpose
    SELECT
        sha2(('loan_purpose' || cast(id as string)), 256) AS ref_hashkey,
        'loan_purpose' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_level_1,
        t_level_1_desc,
        t_level_2,
        t_level_2_desc,
        t_record_status,
        t_curr_no,
        t_inputter,
        t_authoriser,
        t_date_time,
        t_co_code,
        t_category,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_level_1 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_level_1_desc AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_level_2 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_level_2_desc AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_category AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_loan_purpose' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_loan_purpose
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_loan_subproduct
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_loan_subproduct
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_loan_subproduct (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_sub_categ_code bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_loan_subproduct',
    t_category string COMMENT 'Category liên quan',
    t_record_status string COMMENT 'Tình trạng',
    t_curr_no bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_loan_subproduct',
    t_inputter string COMMENT 'Người nhập',
    t_authoriser string COMMENT 'Người duyệt',
    t_date_time string COMMENT 'Ngày giờ cập nhật',
    t_co_code string COMMENT 'Chi nhánh',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_loan_subproduct
    SELECT
        sha2(('loan_subproduct' || cast(id as string)), 256) AS ref_hashkey,
        'loan_subproduct' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_sub_categ_code,
        t_category,
        t_record_status,
        t_curr_no,
        t_inputter,
        t_authoriser,
        t_date_time,
        t_co_code,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_sub_categ_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_category AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_loan_subproduct' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_loan_subproduct
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ocbh_classification
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ocbh_classification
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_classification (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_active_status string COMMENT 'Tình trạng sử dụng',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_classification
    SELECT
        sha2(('classification' || cast(id as string)), 256) AS ref_hashkey,
        'classification' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_active_status,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_active_status AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ocbh_classification' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ocbh_classification
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ocbh_coll_borrow_purpose
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ocbh_coll_borrow_purpose
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_coll_borrow_purpose (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Truong du lieu tu bang nguon t24.t24_ocbh_coll_borrow_purpose',
    id2 string COMMENT 'Truong du lieu tu bang nguon t24.t24_ocbh_coll_borrow_purpose',
    t_curr_no string COMMENT 'Truong du lieu tu bang nguon t24.t24_ocbh_coll_borrow_purpose',
    t_inputter string COMMENT 'Truong du lieu tu bang nguon t24.t24_ocbh_coll_borrow_purpose',
    t_date_time string COMMENT 'Truong du lieu tu bang nguon t24.t24_ocbh_coll_borrow_purpose',
    t_authoriser string COMMENT 'Truong du lieu tu bang nguon t24.t24_ocbh_coll_borrow_purpose',
    t_co_code string COMMENT 'Truong du lieu tu bang nguon t24.t24_ocbh_coll_borrow_purpose',
    t_dept_code string COMMENT 'Truong du lieu tu bang nguon t24.t24_ocbh_coll_borrow_purpose',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_coll_borrow_purpose
    SELECT
        sha2(('coll_borrow_purpose' || cast(id as string)), 256) AS ref_hashkey,
        'coll_borrow_purpose' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_detail as string) AS ref_description,
        data_date,
        id2,
        t_curr_no,
        t_inputter,
        t_date_time,
        t_authoriser,
        t_co_code,
        t_dept_code,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id2 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_detail AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_dept_code AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ocbh_coll_borrow_purpose' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ocbh_coll_borrow_purpose
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ocbh_coll_rev_agent
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ocbh_coll_rev_agent
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_coll_rev_agent (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_inputter string COMMENT 'người nhập',
    t_authoriser string COMMENT 'người duyệt',
    t_date_time string COMMENT 'ngày nhập',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_coll_rev_agent
    SELECT
        sha2(('coll_rev_agent' || cast(id as string)), 256) AS ref_hashkey,
        'coll_rev_agent' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_inputter,
        t_authoriser,
        t_date_time,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ocbh_coll_rev_agent' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ocbh_coll_rev_agent
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ocbh_cus_group
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ocbh_cus_group
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_cus_group (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày hệ thống',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_cus_group
    SELECT
        sha2(('cus_group' || cast(id as string)), 256) AS ref_hashkey,
        'cus_group' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_cust_group_name as string) AS ref_description,
        data_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_cust_group_name AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ocbh_cus_group' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ocbh_cus_group
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ocbh_deposit_prgm
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ocbh_deposit_prgm
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_deposit_prgm (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày hệ thống',
    t_begin_date string COMMENT 'Ngày áp dụng',
    t_end_date string COMMENT 'Ngày kết thúc',
    t_co_code string COMMENT 'Mã CN quản lý',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_deposit_prgm
    SELECT
        sha2(('deposit_prgm' || cast(id as string)), 256) AS ref_hashkey,
        'deposit_prgm' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_prgm_name as string) AS ref_description,
        data_date,
        t_begin_date,
        t_end_date,
        t_co_code,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_prgm_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_begin_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_end_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ocbh_deposit_prgm' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ocbh_deposit_prgm
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ocbh_ft_outward_purpose
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ocbh_ft_outward_purpose
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_ft_outward_purpose (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày hệ thống',
    t_purpose_type string COMMENT 'Loại mục đích  chuyển tiền nước ngoài',
    t_cus_type string COMMENT 'Loại KH',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_ft_outward_purpose
    SELECT
        sha2(('ft_outward_purpose' || cast(id as string)), 256) AS ref_hashkey,
        'ft_outward_purpose' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_desc as string) AS ref_description,
        data_date,
        t_purpose_type,
        t_cus_type,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_purpose_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_desc AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_cus_type AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ocbh_ft_outward_purpose' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ocbh_ft_outward_purpose
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ocbh_fx_buyfcy_purpose
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ocbh_fx_buyfcy_purpose
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_fx_buyfcy_purpose (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_fx_buyfcy_purpose
    SELECT
        sha2(('fx_buyfcy_purpose' || cast(id as string)), 256) AS ref_hashkey,
        'fx_buyfcy_purpose' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ocbh_fx_buyfcy_purpose' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ocbh_fx_buyfcy_purpose
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ocbh_ld_prod_main
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ocbh_ld_prod_main
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_ld_prod_main (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_category string COMMENT 'Mã sản p hẩm',
    t_record_status string COMMENT 'trạng thái của record',
    t_curr_no string COMMENT 'Số lần thay đổi của record',
    t_inputter string COMMENT 'người nhập',
    t_date_time string COMMENT 'ngày nhập',
    t_authoriser string COMMENT 'người duyệt',
    t_co_code string COMMENT 'mã chi nhánh',
    t_dept_code string COMMENT 'mã phòng ban',
    t_auditor_code string COMMENT 'Không dùng',
    t_audit_date_time string COMMENT 'Không dùng',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_ld_prod_main
    SELECT
        sha2(('ld_prod_main' || cast(id as string)), 256) AS ref_hashkey,
        'ld_prod_main' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_name as string) AS ref_description,
        data_date,
        t_category,
        t_record_status,
        t_curr_no,
        t_inputter,
        t_date_time,
        t_authoriser,
        t_co_code,
        t_dept_code,
        t_auditor_code,
        t_audit_date_time,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_category AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_dept_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_auditor_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_audit_date_time AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ocbh_ld_prod_main' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ocbh_ld_prod_main
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ocbh_loan_pro_bundle
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ocbh_loan_pro_bundle
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_loan_pro_bundle (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    sub_product string COMMENT 'Thuộc mã sản phẩm vay',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_loan_pro_bundle
    SELECT
        sha2(('loan_pro_bundle' || cast(id as string)), 256) AS ref_hashkey,
        'loan_pro_bundle' AS ref_type,
        cast(id as string) AS ref_code,
        cast(description as string) AS ref_description,
        data_date,
        sub_product,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(sub_product AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ocbh_loan_pro_bundle' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ocbh_loan_pro_bundle
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ocbh_md_purpose
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ocbh_md_purpose
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_md_purpose (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_parent_id string COMMENT 'mã mđ cha',
    t_n_used string COMMENT 'không còn sử dụng ?',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_md_purpose
    SELECT
        sha2(('md_purpose' || cast(id as string)), 256) AS ref_hashkey,
        'md_purpose' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_purpose_name as string) AS ref_description,
        data_date,
        t_parent_id,
        t_n_used,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_purpose_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_parent_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_n_used AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ocbh_md_purpose' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ocbh_md_purpose
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ocbh_product_package
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ocbh_product_package
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_product_package (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    package_register_fee string COMMENT 'Phí đăng ký gói',
    min_balance string COMMENT 'Số tiền tối thiểu',
    begin_date string COMMENT 'Ngày bắt đầu',
    expire_date string COMMENT 'Ngày hết hạn',
    service string COMMENT 'Tên phí dịch vụ',
    ft_transaction_type string COMMENT 'Mã phí',
    province_type string COMMENT 'Loại phí cùng/khác tỉnh',
    high_low_value string COMMENT 'Giá trị phí cao/thấp',
    external_ft_fee string COMMENT 'Số tiền phí CK ngoài hệ thống',
    external_ft_comm_type string COMMENT 'Mã loại phí CK ngoài hệ thống',
    condition_group string COMMENT 'Nhóm điều kiện',
    min_average_balance string COMMENT 'Số dư bình quân tối thiểu',
    below_aver_bal_fee string COMMENT 'Số tiền phí thu khi số dư TK dưới SDBQ',
    atm_max_amt_trans string COMMENT 'Số tiền max giao dịch ATM',
    atm_max_daily_amt string COMMENT 'Số tiền max giao dịch ATM hàng ngày',
    atm_not_ocb_fee string COMMENT 'Số tiền phí giao dịch khác ATM',
    withdraw_cash_tt_amt string COMMENT 'Số tiền được phép rút tiền mặt',
    withdraw_cash_tt_fee string COMMENT 'Tiền phí rút tiền mặt',
    withdraw_cash_tt_pl string COMMENT 'Mã PL thu phí rút tiền mặt',
    ft_channel string COMMENT 'Kênh giao dịch FT',
    internal_ft_fee string COMMENT 'Tiền phí FT nội bộ',
    internal_ft_comm_type string COMMENT 'Mã phí FT nội bộ',
    bill_payment_fee string COMMENT 'Tiền phí thanh toán hóa đơn',
    bill_payment_comm_type string COMMENT 'Mã phí thanh toán hóa đơn',
    package_customer_type string COMMENT 'Loại khách hàng',
    package_register_pl string COMMENT 'Mã PL thu phí đăng ký gói',
    below_aver_bal_pl string COMMENT 'Mã PL thu phí dưới SDBQ',
    atm_not_ocb_pl string COMMENT 'Mã PL thu phí các giao dịch khác ATM',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_product_package
    SELECT
        sha2(('product_package' || cast(id as string)), 256) AS ref_hashkey,
        'product_package' AS ref_type,
        cast(id as string) AS ref_code,
        cast(package_name as string) AS ref_description,
        data_date,
        package_register_fee,
        min_balance,
        begin_date,
        expire_date,
        service,
        ft_transaction_type,
        province_type,
        high_low_value,
        external_ft_fee,
        external_ft_comm_type,
        condition_group,
        min_average_balance,
        below_aver_bal_fee,
        atm_max_amt_trans,
        atm_max_daily_amt,
        atm_not_ocb_fee,
        withdraw_cash_tt_amt,
        withdraw_cash_tt_fee,
        withdraw_cash_tt_pl,
        ft_channel,
        internal_ft_fee,
        internal_ft_comm_type,
        bill_payment_fee,
        bill_payment_comm_type,
        package_customer_type,
        package_register_pl,
        below_aver_bal_pl,
        atm_not_ocb_pl,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(package_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(package_register_fee AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(min_balance AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(begin_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(expire_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(service AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ft_transaction_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(province_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(high_low_value AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(external_ft_fee AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(external_ft_comm_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(condition_group AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(min_average_balance AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(below_aver_bal_fee AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(atm_max_amt_trans AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(atm_max_daily_amt AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(atm_not_ocb_fee AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(withdraw_cash_tt_amt AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(withdraw_cash_tt_fee AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(withdraw_cash_tt_pl AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ft_channel AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(internal_ft_fee AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(internal_ft_comm_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(bill_payment_fee AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(bill_payment_comm_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(package_customer_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(package_register_pl AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(below_aver_bal_pl AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(atm_not_ocb_pl AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ocbh_product_package' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ocbh_product_package
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ocbt_sub_industry
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ocbt_sub_industry
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbt_sub_industry (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_id_parent string COMMENT 'Mã ngành kinh tế',
    t_order bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_ocbt_sub_industry',
    t_active bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_ocbt_sub_industry',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbt_sub_industry
    SELECT
        sha2(('sub_industry' || cast(id as string)), 256) AS ref_hashkey,
        'sub_industry' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_sub_industry_name as string) AS ref_description,
        data_date,
        t_id_parent,
        t_order,
        t_active,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_sub_industry_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_id_parent AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_order AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_active AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ocbt_sub_industry' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ocbt_sub_industry
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_occupation
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_occupation
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_occupation (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_occupation
    SELECT
        sha2(('occupation' || cast(id as string)), 256) AS ref_hashkey,
        'occupation' AS ref_type,
        cast(id as string) AS ref_code,
        cast(occupation_desc as string) AS ref_description,
        data_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(occupation_desc AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_occupation' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_occupation
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_posting_restrict
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_posting_restrict
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_posting_restrict (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_restriction_type string COMMENT 'Loại hạn chế',
    t_dispo_officer string COMMENT 'Trường không sử dụng',
    t_allow_txn string COMMENT 'Cho phép Hạn chế theo trans code?',
    t_txn_code string COMMENT 'Mã trans code được cho phép/ ko cho phép hạn chế',
    t_local_ref string COMMENT 'Không có trong bảng POSTING.RESTRICT',
    t_alt_override string COMMENT 'Không có trong bảng POSTING.RESTRICT',
    t_block_reason_codes string COMMENT 'Mã lý do hạn chế',
    t_unblock_reason_codes string COMMENT 'Mã lý do gỡ hạn chế',
    t_co_code string COMMENT 'Mã CN quản lý',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_posting_restrict
    SELECT
        sha2(('posting_restrict' || cast(id as string)), 256) AS ref_hashkey,
        'posting_restrict' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_restriction_type,
        t_dispo_officer,
        t_allow_txn,
        t_txn_code,
        t_local_ref,
        t_alt_override,
        t_block_reason_codes,
        t_unblock_reason_codes,
        t_co_code,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_restriction_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_dispo_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_allow_txn AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_txn_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_local_ref AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_alt_override AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_block_reason_codes AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_unblock_reason_codes AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_posting_restrict' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_posting_restrict
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_prod_package_cb
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_prod_package_cb
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_prod_package_cb (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_ac_manage_fee_per string COMMENT 'Phần trăm ưu đãi phí quản lý TK',
    t_ext_ft_fee_per string COMMENT 'Phần trăm ưu đãi phí chuyển tiền NHT online',
    t_ib_fee_per string COMMENT 'Phần trăm ưu đãi phí ebanking',
    t_tax_fee_per string COMMENT 'Phần trăm ưu đãi phí nộp thuế điện tử',
    t_sms_fee_per string COMMENT 'Phần trăm ưu đãi phí SMS',
    t_record_status string COMMENT 'Trạng thái',
    t_curr_no string COMMENT 'Mã số bản ghi',
    t_inputter string COMMENT 'User nhập',
    t_date_time string COMMENT 'Ngày thực hiện',
    t_authoriser string COMMENT 'User duyệt',
    t_co_code string COMMENT 'Mã CNQL',
    t_dept_code string COMMENT 'Trường không sử dụng',
    t_package_fdate string COMMENT 'Ngày bắt đầu',
    t_package_tdate string COMMENT 'Ngày kết thúc',
    t_ac_manage_fee_term string COMMENT 'Thời gian ưu đãi phí quản lý TK',
    t_ext_ft_fee_term string COMMENT 'Thời gian ưu đãi phí chuyển tiền NHT online',
    t_ib_fee_term string COMMENT 'Thời gian ưu đãi phí ebanking',
    t_tax_fee_term string COMMENT 'Thời gian ưu đãi phí nộp thuế điện tử',
    t_sms_fee_term string COMMENT 'Thời gian ưu đãi phí SMS',
    t_ac_min_avr_balance string COMMENT 'Số dư bình quân tối thiểu',
    t_batch_ft_fee_per string COMMENT 'Phần trăm ưu đãi phí chi lô',
    t_batch_ft_fee_term string COMMENT 'Thời gian ưu đãi phí chi lô',
    t_ft_8s_fee_per string COMMENT 'Phần trăm ưu đãi phí chuyển tiền 24/7',
    t_ft_8s_fee_term string COMMENT 'Thời gian ưu đãi phí chuyển tiền 24/7',
    t_ext_fo_fee_per string COMMENT 'Phần trăm ưu đãi phí chuyển tiền NHT tại quầy',
    t_ext_fo_fee_term string COMMENT 'Thời gian ưu đãi phí chuyển tiền NHT tại quầy',
    t_avr_balance_from string COMMENT 'Số dư bình quân_Từ',
    t_avr_balance_to string COMMENT 'Số dư bình quân_Đến',
    t_ac_manage_fee string COMMENT 'Phí quản lý TK',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_prod_package_cb
    SELECT
        sha2(('prod_package_cb' || cast(id as string)), 256) AS ref_hashkey,
        'prod_package_cb' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_package_name as string) AS ref_description,
        data_date,
        t_ac_manage_fee_per,
        t_ext_ft_fee_per,
        t_ib_fee_per,
        t_tax_fee_per,
        t_sms_fee_per,
        t_record_status,
        t_curr_no,
        t_inputter,
        t_date_time,
        t_authoriser,
        t_co_code,
        t_dept_code,
        t_package_fdate,
        t_package_tdate,
        t_ac_manage_fee_term,
        t_ext_ft_fee_term,
        t_ib_fee_term,
        t_tax_fee_term,
        t_sms_fee_term,
        t_ac_min_avr_balance,
        t_batch_ft_fee_per,
        t_batch_ft_fee_term,
        t_ft_8s_fee_per,
        t_ft_8s_fee_term,
        t_ext_fo_fee_per,
        t_ext_fo_fee_term,
        t_avr_balance_from,
        t_avr_balance_to,
        t_ac_manage_fee,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_package_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ac_manage_fee_per AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ext_ft_fee_per AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ib_fee_per AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_tax_fee_per AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_sms_fee_per AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_dept_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_package_fdate AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_package_tdate AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ac_manage_fee_term AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ext_ft_fee_term AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ib_fee_term AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_tax_fee_term AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_sms_fee_term AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ac_min_avr_balance AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_batch_ft_fee_per AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_batch_ft_fee_term AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ft_8s_fee_per AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ft_8s_fee_term AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ext_fo_fee_per AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ext_fo_fee_term AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_avr_balance_from AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_avr_balance_to AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ac_manage_fee AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_prod_package_cb' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_prod_package_cb
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_province
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_province
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_province (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'không dùng ( do thay thế bằng bảng OCBT.PROVINCE)',
    t_nationality string COMMENT 'không dùng ( do thay thế bằng bảng OCBT.PROVINCE)',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_province
    SELECT
        sha2(('province' || cast(id as string)), 256) AS ref_hashkey,
        'province' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_province as string) AS ref_description,
        data_date,
        t_nationality,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_province AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_nationality AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_province' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_province
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_re_stat_line_cont
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_re_stat_line_cont
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_re_stat_line_cont (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Truong du lieu tu bang nguon t24.t24_re_stat_line_cont',
    t_type string COMMENT 'Truong du lieu tu bang nguon t24.t24_re_stat_line_cont',
    t_profit_ccy string COMMENT 'Truong du lieu tu bang nguon t24.t24_re_stat_line_cont',
    t_asst_consol_key string COMMENT 'Truong du lieu tu bang nguon t24.t24_re_stat_line_cont',
    t_asset_type string COMMENT 'Truong du lieu tu bang nguon t24.t24_re_stat_line_cont',
    t_prft_consol_key string COMMENT 'Truong du lieu tu bang nguon t24.t24_re_stat_line_cont',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_re_stat_line_cont
    SELECT
        sha2(('re_stat_line_cont' || cast(id as string)), 256) AS ref_hashkey,
        're_stat_line_cont' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_desc as string) AS ref_description,
        data_date,
        t_type,
        t_profit_ccy,
        t_asst_consol_key,
        t_asset_type,
        t_prft_consol_key,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_desc AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_profit_ccy AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_asst_consol_key AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_asset_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_prft_consol_key AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_re_stat_line_cont' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_re_stat_line_cont
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_re_stat_rep_line
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_re_stat_rep_line
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_re_stat_rep_line (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Không dùng',
    t_k_type string COMMENT 'Không dùng',
    t_co_code string COMMENT 'Không dùng',
    t_inputter string COMMENT 'Không dùng',
    t_date_time string COMMENT 'Không dùng',
    t_authoriser string COMMENT 'Không dùng',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_re_stat_rep_line
    SELECT
        sha2(('re_stat_rep_line' || cast(id as string)), 256) AS ref_hashkey,
        're_stat_rep_line' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_desc as string) AS ref_description,
        data_date,
        t_k_type,
        t_co_code,
        t_inputter,
        t_date_time,
        t_authoriser,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_k_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_desc AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_re_stat_rep_line' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_re_stat_rep_line
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_re_txn_code
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_re_txn_code
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_re_txn_code (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_re_txn_code
    SELECT
        sha2(('re_txn_code' || cast(id as string)), 256) AS ref_hashkey,
        're_txn_code' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_re_txn_code' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_re_txn_code
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_sc_trans_name
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_sc_trans_name
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_sc_trans_name (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_sc_trans_name
    SELECT
        sha2(('sc_trans_name' || cast(id as string)), 256) AS ref_hashkey,
        'sc_trans_name' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_short_name as string) AS ref_description,
        data_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_short_name AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_sc_trans_name' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_sc_trans_name
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_sec_acc_master
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_sec_acc_master
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_sec_acc_master (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_account_officer string COMMENT 'RM/ mã phòng ban quản lý',
    t_customer_number string COMMENT 'trường hệ thống',
    t_reference_currency string COMMENT 'loại tiền',
    t_date_of_valuation string COMMENT 'ngày đánh giá lại',
    t_start_date string COMMENT 'ngày bắt đầu',
    t_co_code string COMMENT 'trường hệ thống',
    t_portfolio_type string COMMENT 'Phân loại portfolio',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_sec_acc_master
    SELECT
        sha2(('sec_acc_master' || cast(id as string)), 256) AS ref_hashkey,
        'sec_acc_master' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_account_name as string) AS ref_description,
        data_date,
        t_account_officer,
        t_customer_number,
        t_reference_currency,
        t_date_of_valuation,
        t_start_date,
        t_co_code,
        t_portfolio_type,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_account_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_customer_number AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_reference_currency AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_account_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_of_valuation AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_start_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_portfolio_type AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_sec_acc_master' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_sec_acc_master
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_sector
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_sector
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_sector (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_sector_group string COMMENT 'Nhóm thành phần kinh tê',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_sector
    SELECT
        sha2(('sector' || cast(id as string)), 256) AS ref_hashkey,
        'sector' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_sector_group,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_sector_group AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_sector' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_sector
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_sub_asset_type
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_sub_asset_type
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_sub_asset_type (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_short_descr string COMMENT 'Tên viết tắt',
    t_asset_type_code string COMMENT 'Mã phân loại nhóm',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_sub_asset_type
    SELECT
        sha2(('sub_asset_type' || cast(id as string)), 256) AS ref_hashkey,
        'sub_asset_type' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_description as string) AS ref_description,
        data_date,
        t_short_descr,
        t_asset_type_code,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_short_descr AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_asset_type_code AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_sub_asset_type' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_sub_asset_type
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_teller_transaction
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_teller_transaction
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_teller_transaction (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_short_desc string COMMENT 'Tên viết tắt',
    t_transaction_code_1 string COMMENT 'Mã loại phí 1',
    t_transaction_code_2 string COMMENT 'Mã loại phí 2',
    t_record_status string COMMENT 'Trạng thái bản ghi',
    t_curr_no string COMMENT 'Số bản ghi',
    t_inputter string COMMENT 'User nhập',
    t_date_time string COMMENT 'Ngày giờ cập nhật',
    t_authoriser string COMMENT 'User duyệt',
    t_co_code string COMMENT 'CN thực hiện',
    t_dept_code string COMMENT 'Trường không sử dụng',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_teller_transaction
    SELECT
        sha2(('teller_transaction' || cast(id as string)), 256) AS ref_hashkey,
        'teller_transaction' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_desc as string) AS ref_description,
        data_date,
        t_short_desc,
        t_transaction_code_1,
        t_transaction_code_2,
        t_record_status,
        t_curr_no,
        t_inputter,
        t_date_time,
        t_authoriser,
        t_co_code,
        t_dept_code,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_short_desc AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_desc AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_transaction_code_1 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_transaction_code_2 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_dept_code AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_teller_transaction' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_teller_transaction
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_town
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_town
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_town (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liêu',
    t_order bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_town',
    t_active string COMMENT 'Tình trạng sử dụng',
    t_province bigint COMMENT 'Truong du lieu tu bang nguon t24.t24_town',
    t_ocb_town_nation string COMMENT 'Truong du lieu tu bang nguon t24.t24_town',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_town
    SELECT
        sha2(('town' || cast(id as string)), 256) AS ref_hashkey,
        'town' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_town_name as string) AS ref_description,
        data_date,
        t_order,
        t_active,
        t_province,
        t_ocb_town_nation,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_order AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_active AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_town_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_province AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ocb_town_nation AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_town' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_town
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_transaction
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_transaction
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_transaction (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    data_date string COMMENT 'Ngày dữ liệu',
    t_transaction_code string COMMENT 'Truong du lieu tu bang nguon t24.t24_transaction',
    t_data_capture string COMMENT 'Không dùng',
    t_cheque_ind string COMMENT 'Không dùng',
    t_mandatory_ref_no string COMMENT 'Không dùng',
    t_debit_credit_ind string COMMENT 'Loại giao dịch ghi nợ hay có',
    t_charge_key string COMMENT 'Không dùng',
    t_immediate_charge string COMMENT 'Không dùng',
    t_default_value_date string COMMENT 'Không dùng',
    t_exposure_date string COMMENT 'Không dùng',
    t_record_status string COMMENT 'Tình trạng bản ghi',
    t_curr_no string COMMENT 'Số lần thay đổi',
    t_co_code string COMMENT 'Mã chi nhánh thực hiện',
    t_dept_code string COMMENT 'Không dùng',
    t_auditor_code string COMMENT 'Không dùng',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_transaction
    SELECT
        sha2(('transaction' || cast(id as string)), 256) AS ref_hashkey,
        'transaction' AS ref_type,
        cast(id as string) AS ref_code,
        cast(t_narrative as string) AS ref_description,
        data_date,
        t_transaction_code,
        t_data_capture,
        t_cheque_ind,
        t_mandatory_ref_no,
        t_debit_credit_ind,
        t_charge_key,
        t_immediate_charge,
        t_default_value_date,
        t_exposure_date,
        t_record_status,
        t_curr_no,
        t_co_code,
        t_dept_code,
        t_auditor_code,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_transaction_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_narrative AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_data_capture AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_cheque_ind AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_mandatory_ref_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_debit_credit_ind AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_charge_key AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_immediate_charge AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_default_value_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_exposure_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_record_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_co_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_dept_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_auditor_code AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_transaction' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_transaction
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_account_type
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_account_type
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_account_type (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    code string COMMENT 'code',
    amnd_state string COMMENT 'Truong du lieu tu bang nguon way4.ows_account_type',
    amnd_date string COMMENT 'Ngày dữ liệu',
    amnd_officer bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_account_type',
    amnd_prev bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_account_type',
    group_name string COMMENT 'Truong du lieu tu bang nguon way4.ows_account_type',
    pcat string COMMENT 'product categroy A: accounting, B: bank accounting, C: issuing, M: acquiring',
    acat string COMMENT 'account category, S: shared limit, P: Payment due, C: Pers limit, O: Other, I: Pay Imediate',
    is_am_available string COMMENT 'Y: Yes, N: No',
    due_type string COMMENT 'Truong du lieu tu bang nguon way4.ows_account_type',
    charge_for_open bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_account_type',
    send_credit_to bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_account_type',
    send_debit_to bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_account_type',
    payment_priority bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_account_type',
    account_status string COMMENT 'Truong du lieu tu bang nguon way4.ows_account_type',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_account_type
    SELECT
        sha2(('w4_ows_account_type' || cast(concat_ws('', cast(id as string), cast(code as string)) as string)), 256) AS ref_hashkey,
        'w4_ows_account_type' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(code as string)) as string) AS ref_code,
        cast(name as string) AS ref_description,
        id,
        code,
        amnd_state,
        amnd_date,
        amnd_officer,
        amnd_prev,
        group_name,
        pcat,
        acat,
        is_am_available,
        due_type,
        charge_for_open,
        send_credit_to,
        send_debit_to,
        payment_priority,
        account_status,
        sha2(
            COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(group_name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(pcat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(acat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(is_am_available AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(due_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(charge_for_open AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(send_credit_to AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(send_debit_to AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(payment_priority AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(account_status AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_account_type' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_account_type
    WHERE id IS NOT NULL
      AND code IS NOT NULL
      AND amnd_state = 'A'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_contr_status
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_contr_status
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_contr_status (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    code string COMMENT 'code',
    amnd_state string COMMENT 'A for active value',
    amnd_date string COMMENT 'Ngày dữ liệu',
    amnd_officer bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_contr_status',
    amnd_prev bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_contr_status',
    con_cat string COMMENT 'contract category, C: card, M: device, A: account',
    external_code string COMMENT 'external code',
    is_valid string COMMENT 'Truong du lieu tu bang nguon way4.ows_contr_status',
    action_type string COMMENT 'Truong du lieu tu bang nguon way4.ows_contr_status',
    restriction_code string COMMENT 'Truong du lieu tu bang nguon way4.ows_contr_status',
    priority_code string COMMENT 'Truong du lieu tu bang nguon way4.ows_contr_status',
    fraud_type string COMMENT 'Truong du lieu tu bang nguon way4.ows_contr_status',
    auth_rc bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_contr_status',
    code_parms string COMMENT 'Truong du lieu tu bang nguon way4.ows_contr_status',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_contr_status
    SELECT
        sha2(('w4_ows_contr_status' || cast(concat_ws('', cast(id as string), cast(code as string)) as string)), 256) AS ref_hashkey,
        'w4_ows_contr_status' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(code as string)) as string) AS ref_code,
        cast(name as string) AS ref_description,
        id,
        code,
        amnd_state,
        amnd_date,
        amnd_officer,
        amnd_prev,
        con_cat,
        external_code,
        is_valid,
        action_type,
        restriction_code,
        priority_code,
        fraud_type,
        auth_rc,
        code_parms,
        sha2(
            COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(con_cat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(external_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(is_valid AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(action_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(restriction_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(priority_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(fraud_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(auth_rc AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(code_parms AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_contr_status' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_contr_status
    WHERE id IS NOT NULL
      AND code IS NOT NULL
      AND amnd_state = 'A'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_cs_status_type
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_cs_status_type
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_cs_status_type (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    amnd_date string COMMENT 'Ngày dữ liệu',
    amnd_officer bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    amnd_state string COMMENT 'A for active',
    amnd_prev bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    code string COMMENT 'code',
    group_code string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    default_value bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    applies_to string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    pcat string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    con_cat string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    ccat string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    status_category string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    log_flag string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    is_primary string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    on_off_mode string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    domain_code string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    domain_type__id bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    add_info string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    is_ready string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_type',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_cs_status_type
    SELECT
        sha2(('w4_ows_cs_status_type' || cast(id as string)), 256) AS ref_hashkey,
        'w4_ows_cs_status_type' AS ref_type,
        cast(id as string) AS ref_code,
        cast(name as string) AS ref_description,
        amnd_date,
        amnd_officer,
        amnd_state,
        amnd_prev,
        code,
        group_code,
        default_value,
        applies_to,
        pcat,
        con_cat,
        ccat,
        status_category,
        log_flag,
        is_primary,
        on_off_mode,
        domain_code,
        domain_type__id,
        add_info,
        is_ready,
        sha2(
            COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(group_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(default_value AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(applies_to AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(pcat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(con_cat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ccat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(status_category AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(log_flag AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(is_primary AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(on_off_mode AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(domain_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(domain_type__id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(add_info AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(is_ready AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_cs_status_type' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_cs_status_type
    WHERE id IS NOT NULL
      AND amnd_state = 'A'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_cs_status_value
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_cs_status_value
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_cs_status_value (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    amnd_date string COMMENT 'Ngày dữ liệu',
    amnd_officer bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_value',
    amnd_state string COMMENT 'A for active',
    amnd_prev bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_value',
    cs_status_type__oid bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_value',
    status_type_code string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_value',
    is_ok string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_value',
    result_event_code string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_value',
    severity_level bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_value',
    to_rules string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_value',
    from_rules string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_value',
    add_info string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_value',
    is_active string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_value',
    date_from string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_value',
    date_to string COMMENT 'Truong du lieu tu bang nguon way4.ows_cs_status_value',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_cs_status_value
    SELECT
        sha2(('w4_ows_cs_status_value' || cast(id as string)), 256) AS ref_hashkey,
        'w4_ows_cs_status_value' AS ref_type,
        cast(id as string) AS ref_code,
        cast(name as string) AS ref_description,
        amnd_date,
        amnd_officer,
        amnd_state,
        amnd_prev,
        cs_status_type__oid,
        status_type_code,
        is_ok,
        result_event_code,
        severity_level,
        to_rules,
        from_rules,
        add_info,
        is_active,
        date_from,
        date_to,
        sha2(
            COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(cs_status_type__oid AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(status_type_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(is_ok AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(result_event_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(severity_level AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(to_rules AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(from_rules AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(add_info AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(is_active AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(date_from AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(date_to AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_cs_status_value' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_cs_status_value
    WHERE id IS NOT NULL
      AND amnd_state = 'A'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_mess_channel
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_mess_channel
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_mess_channel (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    code string COMMENT 'Channel code',
    amnd_state string COMMENT 'A for active',
    amnd_date string COMMENT 'Ngày dữ liệu',
    amnd_officer bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_mess_channel',
    amnd_prev bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_mess_channel',
    contra_channel string COMMENT 'Truong du lieu tu bang nguon way4.ows_mess_channel',
    data_source string COMMENT 'Truong du lieu tu bang nguon way4.ows_mess_channel',
    is_on_us string COMMENT 'Truong du lieu tu bang nguon way4.ows_mess_channel',
    settl_date string COMMENT 'Truong du lieu tu bang nguon way4.ows_mess_channel',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_mess_channel
    SELECT
        sha2(('w4_mess_channel' || cast(concat_ws('', cast(id as string), cast(code as string)) as string)), 256) AS ref_hashkey,
        'w4_mess_channel' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(code as string)) as string) AS ref_code,
        cast(name as string) AS ref_description,
        id,
        code,
        amnd_state,
        amnd_date,
        amnd_officer,
        amnd_prev,
        contra_channel,
        data_source,
        is_on_us,
        settl_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(contra_channel AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(data_source AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(is_on_us AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(settl_date AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_mess_channel' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_mess_channel
    WHERE id IS NOT NULL
      AND code IS NOT NULL
      AND amnd_state = 'A'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_ows_add_data
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_ows_add_data
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_ows_add_data (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    amnd_state string COMMENT 'Truong du lieu tu bang nguon way4.ows_add_data',
    amnd_date string COMMENT 'Ngày dữ liệu',
    amnd_officer bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_add_data',
    amnd_prev bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_add_data',
    add_data_col__id bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_add_data',
    for_id bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_add_data',
    add_data_tab bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_add_data',
    partition_key string COMMENT 'Truong du lieu tu bang nguon way4.ows_add_data',
    data_date string COMMENT 'Truong du lieu tu bang nguon way4.ows_add_data',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_ows_add_data
    SELECT
        sha2(('w4_ows_add_data' || cast(id as string)), 256) AS ref_hashkey,
        'w4_ows_add_data' AS ref_type,
        cast(id as string) AS ref_code,
        cast(val as string) AS ref_description,
        amnd_state,
        amnd_date,
        amnd_officer,
        amnd_prev,
        add_data_col__id,
        for_id,
        add_data_tab,
        partition_key,
        data_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(add_data_col__id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(for_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(add_data_tab AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(val AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(partition_key AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_add_data' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_add_data
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
      AND amnd_state = 'A'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_ows_bank_unit
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_ows_bank_unit
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_ows_bank_unit (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    code string COMMENT 'code',
    amnd_state string COMMENT 'Truong du lieu tu bang nguon way4.ows_bank_unit',
    amnd_date string COMMENT 'Ngày dữ liệu',
    amnd_officer bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_bank_unit',
    amnd_prev bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_bank_unit',
    unit_type string COMMENT 'Truong du lieu tu bang nguon way4.ows_bank_unit',
    bank_unit__oid bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_bank_unit',
    f_i bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_bank_unit',
    liab_contract bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_bank_unit',
    bank_client bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_bank_unit',
    is_ready string COMMENT 'Truong du lieu tu bang nguon way4.ows_bank_unit',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_ows_bank_unit
    SELECT
        sha2(('w4_ows_bank_unit' || cast(concat_ws('', cast(id as string), cast(code as string)) as string)), 256) AS ref_hashkey,
        'w4_ows_bank_unit' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(code as string)) as string) AS ref_code,
        cast(name as string) AS ref_description,
        id,
        code,
        amnd_state,
        amnd_date,
        amnd_officer,
        amnd_prev,
        unit_type,
        bank_unit__oid,
        f_i,
        liab_contract,
        bank_client,
        is_ready,
        sha2(
            COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(unit_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(bank_unit__oid AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(f_i AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(liab_contract AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(bank_client AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(is_ready AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_bank_unit' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_bank_unit
    WHERE id IS NOT NULL
      AND code IS NOT NULL
      AND amnd_state = 'A'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_ows_bin_table
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_ows_bin_table
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_ows_bin_table (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    amnd_state string COMMENT 'A for active value',
    amnd_date string COMMENT 'Ngày dữ liệu',
    amnd_officer bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    amnd_prev bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    bin_group__oid bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    member_id string COMMENT 'Bank ID',
    start_bin string COMMENT 'Start BIN card',
    end_bin string COMMENT 'End BIN card',
    start_bin_4 string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    pan_length bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    bin_condition string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    bin_details string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    card_brand string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    card_org string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    card_technology string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    cdv_algorithm string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    channel string COMMENT 'Card Scheme: V for Visa, E for MasterCard, J for JCB',
    country string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    data_source string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    ec_atm_type string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    forwarding_id string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    ica_number string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    processing_class string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    product_id string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    licensed_product_id string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    product_category string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    region_for_issuer string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    service_indicator string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    terminal_category string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    usage string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    usage_domain string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    bin_status string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    data_date string COMMENT 'Truong du lieu tu bang nguon way4.ows_bin_table',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_ows_bin_table
    SELECT
        sha2(('w4_ows_bin_table' || cast(id as string)), 256) AS ref_hashkey,
        'w4_ows_bin_table' AS ref_type,
        cast(id as string) AS ref_code,
        cast(name as string) AS ref_description,
        amnd_state,
        amnd_date,
        amnd_officer,
        amnd_prev,
        bin_group__oid,
        member_id,
        start_bin,
        end_bin,
        start_bin_4,
        pan_length,
        bin_condition,
        bin_details,
        card_brand,
        card_org,
        card_technology,
        cdv_algorithm,
        channel,
        country,
        data_source,
        ec_atm_type,
        forwarding_id,
        ica_number,
        processing_class,
        product_id,
        licensed_product_id,
        product_category,
        region_for_issuer,
        service_indicator,
        terminal_category,
        usage,
        usage_domain,
        bin_status,
        data_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(bin_group__oid AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(member_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(start_bin AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(end_bin AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(start_bin_4 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(pan_length AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(bin_condition AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(bin_details AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(card_brand AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(card_org AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(card_technology AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(cdv_algorithm AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(channel AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(country AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(data_source AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ec_atm_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(forwarding_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(ica_number AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(processing_class AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(product_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(licensed_product_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(product_category AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(region_for_issuer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(service_indicator AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(terminal_category AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(usage AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(usage_domain AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(bin_status AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_bin_table' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_bin_table
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
      AND amnd_state = 'A'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_ows_event_type
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_ows_event_type
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_ows_event_type (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    code string COMMENT 'event code',
    amnd_state string COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    amnd_date string COMMENT 'Ngày dữ liệu',
    amnd_officer bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    amnd_prev bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    group_code string COMMENT 'event group',
    f_i bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    pcat string COMMENT 'product category, C: issuing ,M: acquiring, A: accounting, B: bank accounting',
    con_cat string COMMENT 'contract category, A: account, C: card ,M: device',
    event_renew_type string COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    event_period bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    due_to_work_day string COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    post_immediate string COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    fee_type bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    new_status bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    next_event bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    start_job bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    client_stop_list string COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    cr_limit_action string COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    used_in_history string COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    suppl_formula string COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    custom_event_code string COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    special_parms string COMMENT 'Truong du lieu tu bang nguon way4.ows_event_type',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_ows_event_type
    SELECT
        sha2(('w4_ows_event_type' || cast(concat_ws('', cast(id as string), cast(code as string)) as string)), 256) AS ref_hashkey,
        'w4_ows_event_type' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(code as string)) as string) AS ref_code,
        cast(name as string) AS ref_description,
        id,
        code,
        amnd_state,
        amnd_date,
        amnd_officer,
        amnd_prev,
        group_code,
        f_i,
        pcat,
        con_cat,
        event_renew_type,
        event_period,
        due_to_work_day,
        post_immediate,
        fee_type,
        new_status,
        next_event,
        start_job,
        client_stop_list,
        cr_limit_action,
        used_in_history,
        suppl_formula,
        custom_event_code,
        special_parms,
        sha2(
            COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(group_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(f_i AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(pcat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(con_cat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(event_renew_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(event_period AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(due_to_work_day AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(post_immediate AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(fee_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(new_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(next_event AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(start_job AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(client_stop_list AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(cr_limit_action AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(used_in_history AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(suppl_formula AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(custom_event_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(special_parms AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_event_type' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_event_type
    WHERE id IS NOT NULL
      AND code IS NOT NULL
      AND amnd_state = 'A'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_ows_evnt_action
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_ows_evnt_action
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_ows_evnt_action (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    action_code string,
    usage_action__oid bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_evnt_action',
    new_id bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_evnt_action',
    old_id bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_evnt_action',
    status string COMMENT 'Truong du lieu tu bang nguon way4.ows_evnt_action',
    data_date string COMMENT 'Truong du lieu tu bang nguon way4.ows_evnt_action',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_ows_evnt_action
    SELECT
        sha2(('w4_ows_evnt_action' || cast(concat_ws('', cast(id as string), cast(action_code as string)) as string)), 256) AS ref_hashkey,
        'w4_ows_evnt_action' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(action_code as string)) as string) AS ref_code,
        cast(event_details as string) AS ref_description,
        id,
        action_code,
        usage_action__oid,
        new_id,
        old_id,
        status,
        data_date,
        sha2(
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(usage_action__oid AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(action_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(new_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(old_id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(event_details AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_evnt_action' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_evnt_action
    WHERE id IS NOT NULL
      AND action_code IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_ows_td_auth_type
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_ows_td_auth_type
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_ows_td_auth_type (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    code string,
    amnd_date string COMMENT 'Ngày dữ liệu',
    amnd_officer bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_td_auth_type',
    amnd_state string COMMENT 'Truong du lieu tu bang nguon way4.ows_td_auth_type',
    amnd_prev bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_td_auth_type',
    auth_type_cat string COMMENT 'Truong du lieu tu bang nguon way4.ows_td_auth_type',
    idt_required string COMMENT 'Truong du lieu tu bang nguon way4.ows_td_auth_type',
    version_idt string COMMENT 'Truong du lieu tu bang nguon way4.ows_td_auth_type',
    base_type bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_td_auth_type',
    is_ready string COMMENT 'Truong du lieu tu bang nguon way4.ows_td_auth_type',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_ows_td_auth_type
    SELECT
        sha2(('w4_ows_td_auth_type' || cast(concat_ws('', cast(id as string), cast(code as string)) as string)), 256) AS ref_hashkey,
        'w4_ows_td_auth_type' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(code as string)) as string) AS ref_code,
        cast(name as string) AS ref_description,
        id,
        code,
        amnd_date,
        amnd_officer,
        amnd_state,
        amnd_prev,
        auth_type_cat,
        idt_required,
        version_idt,
        base_type,
        is_ready,
        sha2(
            COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(auth_type_cat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(idt_required AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(version_idt AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(base_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(is_ready AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_td_auth_type' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_td_auth_type
    WHERE id IS NOT NULL
      AND code IS NOT NULL
      AND amnd_state = 'A'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_resp_code
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_resp_code
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_resp_code (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    resp_code bigint,
    amnd_state string COMMENT 'A for active',
    amnd_date string COMMENT 'Ngày dữ liệu',
    amnd_officer bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_resp_code',
    amnd_prev bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_resp_code',
    resp_level bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_resp_code',
    message_code string COMMENT 'Truong du lieu tu bang nguon way4.ows_resp_code',
    is_status string COMMENT 'Truong du lieu tu bang nguon way4.ows_resp_code',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_resp_code
    SELECT
        sha2(('w4_resp_code' || cast(concat_ws('', cast(id as string), cast(resp_code as string)) as string)), 256) AS ref_hashkey,
        'w4_resp_code' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(resp_code as string)) as string) AS ref_code,
        cast(resp_text as string) AS ref_description,
        id,
        resp_code,
        amnd_state,
        amnd_date,
        amnd_officer,
        amnd_prev,
        resp_level,
        message_code,
        is_status,
        sha2(
            COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(resp_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(resp_text AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(resp_level AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(message_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(is_status AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_resp_code' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_resp_code
    WHERE id IS NOT NULL
      AND resp_code IS NOT NULL
      AND amnd_state = 'A'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_sic
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_sic
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_sic (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    code string COMMENT 'Merchant Category Code',
    amnd_state string COMMENT 'A for active value',
    amnd_date string COMMENT 'Ngày dữ liệu',
    amnd_officer bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_sic',
    amnd_prev bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_sic',
    group_code string COMMENT 'Merchant Category Group',
    custom_code string COMMENT 'Truong du lieu tu bang nguon way4.ows_sic',
    limit_code string COMMENT 'Truong du lieu tu bang nguon way4.ows_sic',
    sic_group_dflt bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_sic',
    use_in_bank string COMMENT 'Truong du lieu tu bang nguon way4.ows_sic',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_sic
    SELECT
        sha2(('w4_ows_sic' || cast(concat_ws('', cast(id as string), cast(code as string)) as string)), 256) AS ref_hashkey,
        'w4_ows_sic' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(code as string)) as string) AS ref_code,
        cast(name as string) AS ref_description,
        id,
        code,
        amnd_state,
        amnd_date,
        amnd_officer,
        amnd_prev,
        group_code,
        custom_code,
        limit_code,
        sic_group_dflt,
        use_in_bank,
        sha2(
            COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(group_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(custom_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(limit_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(sic_group_dflt AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(use_in_bank AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_sic' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_sic
    WHERE id IS NOT NULL
      AND code IS NOT NULL
      AND amnd_state = 'A'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_trans_cond
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_trans_cond
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_trans_cond (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    id bigint,
    code string COMMENT 'Transaction condition code',
    name string COMMENT 'Transaction condition name',
    condition_details string,
    amnd_state string COMMENT 'A for active value',
    amnd_date string COMMENT 'Ngày dữ liệu',
    amnd_officer bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_cond',
    amnd_prev bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_cond',
    term_cat string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_cond',
    category_code string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_cond',
    default_condition bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_cond',
    late_condition bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_cond',
    security_code string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_cond',
    addendum string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_cond',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_trans_cond
    SELECT
        sha2(('w4_trans_cond' || cast(concat_ws('', cast(id as string), cast(code as string)) as string)), 256) AS ref_hashkey,
        'w4_trans_cond' AS ref_type,
        cast(concat_ws('', cast(id as string), cast(code as string)) as string) AS ref_code,
        cast(name || condition_details as string) AS ref_description,
        id,
        code,
        name,
        condition_details,
        amnd_state,
        amnd_date,
        amnd_officer,
        amnd_prev,
        term_cat,
        category_code,
        default_condition,
        late_condition,
        security_code,
        addendum,
        sha2(
            COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(term_cat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(category_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(condition_details AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(default_condition AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(late_condition AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(security_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(addendum AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_trans_cond' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_trans_cond
    WHERE id IS NOT NULL
      AND code IS NOT NULL
      AND amnd_state = 'A'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_way4_trans_type
-- =============================================================================
DECLARE OR REPLACE VARIABLE end_date STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_way4_trans_type
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_way4_trans_type (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    ref_type string COMMENT 'Loai reference',
    ref_code string COMMENT 'Ma code reference',
    ref_description string COMMENT 'Mo ta reference',
    amnd_state string COMMENT 'A for active value',
    amnd_date string COMMENT 'Ngày dữ liệu',
    amnd_officer bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    amnd_prev bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    service_class string COMMENT 'T: Transaction, M: Miscellaneous',
    s_cat string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    t_cat string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    dr_cr bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    is_impersonal string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    is_authorized string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    is_required string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    enable_adjustment string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    enable_reversal string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    enable_request string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    prev_trans_type bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    chain_type string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    charge_event string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    dispute_trn_class string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    terminal_category string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    production_type string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    production_event string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    trans_code string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    reversal_code string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    trans_type_idt string COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    priority bigint COMMENT 'Truong du lieu tu bang nguon way4.ows_trans_type',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_way4_trans_type
    SELECT
        sha2(('w4_trans_type' || cast(id as string)), 256) AS ref_hashkey,
        'w4_trans_type' AS ref_type,
        cast(id as string) AS ref_code,
        cast(name as string) AS ref_description,
        amnd_state,
        amnd_date,
        amnd_officer,
        amnd_prev,
        service_class,
        s_cat,
        t_cat,
        dr_cr,
        is_impersonal,
        is_authorized,
        is_required,
        enable_adjustment,
        enable_reversal,
        enable_request,
        prev_trans_type,
        chain_type,
        charge_event,
        dispute_trn_class,
        terminal_category,
        production_type,
        production_event,
        trans_code,
        reversal_code,
        trans_type_idt,
        priority,
        sha2(
            COALESCE(UPPER(TRIM(CAST(amnd_state AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_officer AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(amnd_prev AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(name AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(service_class AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(s_cat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_cat AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(dr_cr AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(is_impersonal AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(is_authorized AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(is_required AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(enable_adjustment AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(enable_reversal AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(enable_request AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(prev_trans_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(chain_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(charge_event AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(dispute_trn_class AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(terminal_category AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(production_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(production_event AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(trans_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(reversal_code AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(trans_type_idt AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(priority AS string))), ''),
            256
        ) AS hashdiff,
        to_date(end_date, 'yyyyMMdd') AS source_event_date,
        cast('way4__ows_trans_type' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.way4.ows_trans_type
    WHERE id IS NOT NULL
      AND amnd_state = 'A'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY etl_time ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_acct_group_condition
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_acct_group_condition
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_acct_group_condition (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    id string COMMENT 'Mã nhóm Tài khoản và loại tiền tệ',
    t_minimum_bal decimal(38,10) COMMENT 'Số dư tối thiểu',
    t_curr_no bigint COMMENT 'Số bản ghi',
    inputter string COMMENT 'User nhập',
    t_date_time string COMMENT 'Ngày thực hiện',
    t_authoriser string COMMENT 'User duyệt',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_acct_group_condition
    SELECT
        sha2(('acct_group_condition' || cast(id as string)), 256) AS ref_hashkey,
        id,
        t_minimum_bal,
        t_curr_no,
        inputter,
        t_date_time,
        t_authoriser,
        sha2(
            COALESCE(UPPER(TRIM(CAST(t_minimum_bal AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_acct_group_condition' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_acct_group_condition
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_denom_exchange
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_denom_exchange
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_denom_exchange (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    id string COMMENT 'Loại tiền',
    data_date string COMMENT 'Ngày dữ liệu',
    t_denomination string COMMENT 'Mệnh giá',
    t_denom_buy_rate string COMMENT 'Tỷ giá mua',
    t_denom_sell_rate string COMMENT 'Tỷ giá bán',
    t_denom_revl_rate string COMMENT 'Tỷ giá đánh giá lại',
    t_denom_rate_sprd string COMMENT 'N/A',
    t_curr_no string COMMENT 'Số lần thay đổi',
    t_inputter string COMMENT 'Người nhập',
    t_date_time string COMMENT 'Ngày giờ thay đổi',
    t_authoriser string COMMENT 'Người duyệt',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_denom_exchange
    SELECT
        sha2(('denom_exchange' || cast(id as string)), 256) AS ref_hashkey,
        id,
        data_date,
        t_denomination,
        t_denom_buy_rate,
        t_denom_sell_rate,
        t_denom_revl_rate,
        t_denom_rate_sprd,
        t_curr_no,
        t_inputter,
        t_date_time,
        t_authoriser,
        sha2(
            COALESCE(UPPER(TRIM(CAST(data_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_denomination AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_denom_buy_rate AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_denom_sell_rate AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_denom_revl_rate AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_denom_rate_sprd AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_curr_no AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inputter AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_date_time AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_authoriser AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_denom_exchange' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_denom_exchange
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_group_capitalisation
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_group_capitalisation
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_group_capitalisation (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    id string COMMENT 'ID nhóm tài khoản',
    data_date string COMMENT 'Ngày dữ liệu',
    t_dr_cap_frequency string COMMENT 'Định kỳ kép lãi ghi nợ',
    t_cr_cap_frequency string COMMENT 'Định kỳ kép lãi ghi có',
    t_settle_acct_close string COMMENT 'Cần TK chỉ định kép lãi khác khi TK này đóng',
    t_start_of_day_cap string COMMENT 'Kép lãi đầu ngày hay không',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_group_capitalisation
    SELECT
        sha2(('group_capitalisation' || cast(id as string)), 256) AS ref_hashkey,
        id,
        data_date,
        t_dr_cap_frequency,
        t_cr_cap_frequency,
        t_settle_acct_close,
        t_start_of_day_cap,
        sha2(
            COALESCE(UPPER(TRIM(CAST(data_date AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_dr_cap_frequency AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_cr_cap_frequency AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_settle_acct_close AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_start_of_day_cap AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_group_capitalisation' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_group_capitalisation
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_lc_enrichment
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_lc_enrichment
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_lc_enrichment (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    id string COMMENT 'Mã Enrichment',
    t_operation string COMMENT 'Không dùng',
    t_revocable string COMMENT 'Không dùng',
    t_ucp_ind string COMMENT 'Không dùng',
    t_part_ship string COMMENT 'Không dùng',
    t_transship string COMMENT 'Không dùng',
    t_reimburse string COMMENT 'Không dùng',
    t_charges_from string COMMENT 'Không dùng',
    t_party_chrgd string COMMENT 'Không dùng',
    t_chrg_status string COMMENT 'Không dùng',
    t_drawing_type string COMMENT 'Không dùng',
    t_pay_method string COMMENT 'Không dùng',
    t_coll_reply string COMMENT 'Không dùng',
    t_chrg_period string COMMENT 'Không dùng',
    t_imp_exp string COMMENT 'Không dùng',
    t_pay_type string COMMENT 'Không dùng',
    t_inco_terms string COMMENT 'Không dùng',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_lc_enrichment
    SELECT
        sha2(('lc_enrichment' || cast(id as string)), 256) AS ref_hashkey,
        id,
        t_operation,
        t_revocable,
        t_ucp_ind,
        t_part_ship,
        t_transship,
        t_reimburse,
        t_charges_from,
        t_party_chrgd,
        t_chrg_status,
        t_drawing_type,
        t_pay_method,
        t_coll_reply,
        t_chrg_period,
        t_imp_exp,
        t_pay_type,
        t_inco_terms,
        sha2(
            COALESCE(UPPER(TRIM(CAST(t_operation AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_revocable AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_ucp_ind AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_part_ship AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_transship AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_reimburse AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_charges_from AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_party_chrgd AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_chrg_status AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_drawing_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_pay_method AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_coll_reply AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_chrg_period AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_imp_exp AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_pay_type AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_inco_terms AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_lc_enrichment' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_lc_enrichment
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: ref_t24_ocbh_industry_tt15
-- =============================================================================
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20210101';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260508';


-- -----------------------------------------------------------------------------
-- ref_t24_ocbh_industry_tt15
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_industry_tt15 (
    ref_hashkey string COMMENT 'Hash key cua bang reference (sha256)',
    id string COMMENT 'Hệ thống tự sinh tăng dần bắt đầu từ 1 Tối đa 6 ký số',
    t_industry_tt15_l1 string COMMENT 'Mã ngành cấp 1',
    t_industry_tt15_l2 string COMMENT 'Mã ngành cấp 2',
    t_industry_tt15_l3 string COMMENT 'Mã ngành cấp 3',
    t_industry_name string COMMENT 'Tên ngành kinh tế',
    hashdiff string COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date date COMMENT 'Ngay du lieu tu nguon',
    record_source string COMMENT 'Nguon du lieu',
    load_timestamp timestamp COMMENT 'Thoi diem load du lieu'
)
USING DELTA
PARTITIONED BY (source_event_date)
;

-- =============================================================================

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.ref_t24_ocbh_industry_tt15
    SELECT
        sha2(('ocbh_industry_tt15' || cast(id as string)), 256) AS ref_hashkey,
        id,
        t_industry_tt15_l1,
        t_industry_tt15_l2,
        t_industry_tt15_l3,
        t_industry_name,
        sha2(
            COALESCE(UPPER(TRIM(CAST(t_industry_tt15_l1 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_industry_tt15_l2 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_industry_tt15_l3 AS string))), '') || '$' ||
            COALESCE(UPPER(TRIM(CAST(t_industry_name AS string))), ''),
            256
        ) AS hashdiff,
        to_date(data_date, 'yyyyMMdd') AS source_event_date,
        cast('t24__t24_ocbh_industry_tt15' as string) AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM ocb_datavault_prod_sourcing.t24.t24_ocbh_industry_tt15
    WHERE to_date(data_date, 'yyyyMMdd') BETWEEN to_date(start_date, 'yyyyMMdd') AND to_date(end_date, 'yyyyMMdd')
      AND id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ref_hashkey, hashdiff ORDER BY source_event_date ASC) = 1
;

-- =============================================================================
-- BACKFILL: reference (bang tong hop tat ca ref_* table)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- reference (VIEW - placeholder schema tam thoi, chua UNION ALL tu 84 bang ref_*
-- vi cac bang nay chua ton tai/chua chay o prod. Bo sung logic UNION ALL sau.)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE VIEW ocb_datavault_prod_cleaned.raw_vault.reference (
    ref_hashkey COMMENT 'Hash key cua bang reference (sha256)',
    ref_type COMMENT 'Loai reference',
    ref_code COMMENT 'Ma code reference',
    ref_description COMMENT 'Mo ta reference',
    ref_all_attributes COMMENT 'Toan bo cac cot nghiep vu con lai, dang JSON',
    hashdiff COMMENT 'Hash diff toan bo cac truong (sha256)',
    source_event_date COMMENT 'Ngay du lieu tu nguon',
    record_source COMMENT 'Nguon du lieu',
    load_timestamp COMMENT 'Thoi diem load du lieu'
) AS
SELECT
    CAST(NULL AS STRING) AS ref_hashkey,
    CAST(NULL AS STRING) AS ref_type,
    CAST(NULL AS STRING) AS ref_code,
    CAST(NULL AS STRING) AS ref_description,
    CAST(NULL AS STRING) AS ref_all_attributes,
    CAST(NULL AS STRING) AS hashdiff,
    CAST(NULL AS DATE) AS source_event_date,
    CAST(NULL AS STRING) AS record_source,
    CAST(NULL AS TIMESTAMP) AS load_timestamp
WHERE 1 = 0
;
