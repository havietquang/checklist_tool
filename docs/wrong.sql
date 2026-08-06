
WITH
-- ---------- III.4.2.1 STS HUB: giao_dich ----------
giao_dich_sts_del AS (
    SELECT giao_dich_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_giao_dich')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY giao_dich_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
giao_dich_active AS (
    SELECT h.giao_dich_hashkey, h.business_key, h.source_event_date
    FROM IDENTIFIER(:cleaned || '.raw_vault.hub_giao_dich') h
    LEFT JOIN giao_dich_sts_del d ON d.giao_dich_hashkey = h.giao_dich_hashkey
    WHERE h.source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
      AND d.giao_dich_hashkey IS NULL
),
-- ---------- III.4.2.1 STS HUB: khach_hang ----------
khach_hang_sts_del AS (
    SELECT khach_hang_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_khach_hang')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY khach_hang_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
khach_hang_active AS (
    SELECT h.khach_hang_hashkey, h.business_key, h.source_event_date
    FROM IDENTIFIER(:cleaned || '.raw_vault.hub_khach_hang') h
    LEFT JOIN khach_hang_sts_del d ON d.khach_hang_hashkey = h.khach_hang_hashkey
    WHERE h.source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
      AND d.khach_hang_hashkey IS NULL
),
-- ---------- III.4.2.1 STS HUB: auth_to_chuc_don_vi ----------
auth_to_chuc_don_vi_sts_del AS (
    SELECT auth_to_chuc_don_vi_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.sts_hub_auth_to_chuc_don_vi')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY auth_to_chuc_don_vi_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
auth_to_chuc_don_vi_active AS (
    SELECT h.auth_to_chuc_don_vi_hashkey, h.business_key, h.source_event_date
    FROM IDENTIFIER(:cleaned || '.raw_vault.hub_auth_to_chuc_don_vi') h
    LEFT JOIN auth_to_chuc_don_vi_sts_del d ON d.auth_to_chuc_don_vi_hashkey = h.auth_to_chuc_don_vi_hashkey
    WHERE h.source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
      AND d.auth_to_chuc_don_vi_hashkey IS NULL
),
-- ---------- III.4.2.3 LINK 1:N: giao_dich -> khach_hang ----------
-- driving key = giao_dich_hashkey (mot giao dich thuoc mot khach hang)
link_giao_dich_khach_hang_cur AS (
    SELECT giao_dich_hashkey,
           max_by(khach_hang_hashkey, source_event_date) AS khach_hang_hashkey
    FROM IDENTIFIER(:cleaned || '.raw_vault.link_giao_dich_khach_hang')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY giao_dich_hashkey
),
-- ---------- III.4.2.2 SATELLITE (single-active) ----------
giao_dich_ttc_sat AS (
    SELECT giao_dich_hashkey,
           max_by(quy_trinh,            source_event_date) AS quy_trinh,
           max_by(vai_tro_nguoi_xl,     source_event_date) AS vai_tro_nguoi_xl,
           max_by(nguoi_xu_ly_id,       source_event_date) AS nguoi_xu_ly_id,
           max_by(trang_thai,           source_event_date) AS trang_thai,
           max_by(trang_thai_hoat_dong, source_event_date) AS trang_thai_hoat_dong,
           max_by(don_vi_tao,           source_event_date) AS don_vi_tao,
           max_by(nguoi_tao_id,         source_event_date) AS nguoi_tao_id,
           max_by(ngay_tao,             source_event_date) AS ngay_tao,
           max_by(ngay_hoan_thanh,      source_event_date) AS ngay_hoan_thanh,
           max_by(process_id,           source_event_date) AS process_id
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_giao_dich_thong_tin_chung')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY giao_dich_hashkey
),
giao_dich_tdcn_ttc_sat AS (
    SELECT giao_dich_hashkey,
           max_by(luong_phe_duyet, source_event_date) AS luong_phe_duyet
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_giao_dich_tdcn_thong_tin_chung')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY giao_dich_hashkey
),
khach_hang_sat AS (
    SELECT khach_hang_hashkey,
           max_by(ten_khach_hang, source_event_date) AS ten_khach_hang
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_khach_hang_thong_tin_chung')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY khach_hang_hashkey
),
auth_to_chuc_don_vi_sat AS (
    SELECT auth_to_chuc_don_vi_hashkey,
           max_by(ten_don_vi, source_event_date) AS ten_don_vi
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_auth_to_chuc_don_vi')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY auth_to_chuc_don_vi_hashkey
),
giao_dich_ct_user_sat AS (
    SELECT giao_dich_hashkey,
           max_by(user_vitri_1, source_event_date) AS user_vitri_1,
           max_by(user_vitri_2, source_event_date) AS user_vitri_2,
           max_by(user_vitri_3, source_event_date) AS user_vitri_3,
           max_by(user_vitri_4, source_event_date) AS user_vitri_4,
           max_by(user_vitri_5, source_event_date) AS user_vitri_5,
           max_by(user_vitri_6, source_event_date) AS user_vitri_6,
           max_by(user_vitri_7, source_event_date) AS user_vitri_7
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_giao_dich_chi_tiet_user')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY giao_dich_hashkey
),
-- satellite ngoai DV, khoa nghiep vu = process_id (giu nguyen dieu kien join goc)
external_transaction_sat AS (
    SELECT process_id,
           max_by(refcode, source_event_date) AS refcode
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_external_transaction_information')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY process_id
),
-- ---------- III.4.2.2 SATELLITE (multi-active: subseq_key = luong_them) ----------
giao_dich_tdcn_tsbd_sat AS (
    SELECT giao_dich_hashkey, luong_them,
           max_by(so_luong,  source_event_date) AS so_luong,
           max_by(loai_tsbd, source_event_date) AS loai_tsbd
    FROM IDENTIFIER(:cleaned || '.raw_vault.sat_giao_dich_tdcn_tai_san_bao_dam')
    WHERE source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY giao_dich_hashkey, luong_them
),
-- ---------- Tap giao dich dang hieu luc + thuoc tinh ----------
GD AS (
    SELECT
        h.giao_dich_hashkey            AS GIAO_DICH_HASHKEY,
        h.business_key                 AS GD_ID,
        s.quy_trinh                    AS QUY_TRINH,
        s.vai_tro_nguoi_xl             AS VAI_TRO_NGUOI_XL,
        s.nguoi_xu_ly_id               AS NGUOI_XU_LY_ID,
        s.trang_thai                   AS TRANG_THAI,
        s.trang_thai_hoat_dong         AS TRANG_THAI_HOAT_DONG,
        s.don_vi_tao                   AS DON_VI_TAO,
        s.nguoi_tao_id                 AS NGUOI_TAO_ID,
        s.ngay_tao                     AS NGAY_TAO,
        s.ngay_hoan_thanh              AS NGAY_HOAN_THANH,
        s.process_id                   AS PROCESS_ID,
        hk.khach_hang_hashkey          AS KHACH_HANG_HASHKEY
    FROM giao_dich_active h
    LEFT JOIN giao_dich_ttc_sat s
        ON h.giao_dich_hashkey = s.giao_dich_hashkey
    LEFT JOIN link_giao_dich_khach_hang_cur lk
        ON h.giao_dich_hashkey = lk.giao_dich_hashkey
    LEFT JOIN khach_hang_active hk
        ON lk.khach_hang_hashkey = hk.khach_hang_hashkey
)
SELECT
    GD.PROCESS_ID,
    GD.GD_ID AS MA_GIAO_DICH,
    KH.ten_khach_hang AS KHACH_HANG_TEN,
    donVi.ten_don_vi AS DON_VI_KHOI_TAO_TEN,
    trangThai.Ref_description AS TRANG_THAI_TEN,
    trangThaiHD.Ref_description AS TRANG_THAI_HOAT_DONG_TEN,
    luongPD.Ref_description AS LUONG_PHE_DUYET_TEN,
    -- NGUOI_DANG_XU_LY (transform)
    CASE
        WHEN GD.TRANG_THAI_HOAT_DONG = 1022 THEN 'GD HOAN THANH'
        WHEN GD.TRANG_THAI_HOAT_DONG = 1024 THEN 'GD DONG'
        WHEN UPPER(GD.NGUOI_XU_LY_ID) = 'ADMINPCT' THEN 'CHO PHAN CONG TU DONG'
        WHEN UPPER(GD.NGUOI_XU_LY_ID) = 'ADMINPPDTD' THEN 'ADMIN PHAN CONG'
        WHEN GD.NGUOI_XU_LY_ID IS NULL THEN 'TKBBH'
        ELSE UPPER(GD.NGUOI_XU_LY_ID)
    END AS NGUOI_DANG_XU_LY,
    -- VAI_TRO_NGUOI_XL_TEN (transform)
    CASE
        WHEN GD.TRANG_THAI IN (5351, 5366, 8504, 8703, 1315) THEN 'HE THONG BPM'
        ELSE NHOM.Ref_description
    END AS VAI_TRO_NGUOI_XL_TEN,
    GD.NGUOI_TAO_ID AS NGUOI_KHOI_TAO,
    GD.NGAY_TAO AS NGAY_KHOI_TAO,
    GD.NGAY_HOAN_THANH,
    -- CBTTD (transform)
    CASE
        WHEN GD.VAI_TRO_NGUOI_XL = 11 THEN GD.NGUOI_XU_LY_ID
        WHEN TTC.luong_phe_duyet = 5304 AND GD.VAI_TRO_NGUOI_XL != 11 THEN CTGD.user_vitri_1
        ELSE ''
    END AS CBTTD,
    -- CPD (transform)
    CASE
        WHEN GD.VAI_TRO_NGUOI_XL IN (13, 20) THEN GD.NGUOI_XU_LY_ID
        WHEN TTC.luong_phe_duyet = 5303 THEN CTGD.user_vitri_1
        WHEN TTC.luong_phe_duyet = 5304 THEN CTGD.user_vitri_7
        ELSE ''
    END AS CPD,
    CTGD.user_vitri_6 AS CBDVTD,
    CASE WHEN GD.VAI_TRO_NGUOI_XL = 448 THEN GD.NGUOI_XU_LY_ID ELSE CTGD.user_vitri_2 END AS CBGDTD_ST,
    CASE WHEN GD.VAI_TRO_NGUOI_XL = 447 THEN GD.NGUOI_XU_LY_ID ELSE CTGD.user_vitri_3 END AS CPD_ST,
    CASE WHEN GD.VAI_TRO_NGUOI_XL = 450 THEN GD.NGUOI_XU_LY_ID ELSE CTGD.user_vitri_4 END AS CBGDTD_XL,
    CASE WHEN GD.VAI_TRO_NGUOI_XL = 449 THEN GD.NGUOI_XU_LY_ID ELSE CTGD.user_vitri_5 END AS CPD_XL,
    EXTR.refcode AS REFCODE,
    dmTSBD.Ref_description AS LOAI_TSBD,
    TSBD_ST.so_luong AS SO_LUONG_TSBD_ST,
    TSBD_XL.so_luong AS SO_LUONG_TSBD_XL,
    TO_DATE(:DATADT, 'yyyyMMdd') AS DATA_DT
FROM GD
LEFT JOIN giao_dich_tdcn_ttc_sat TTC
    ON TTC.giao_dich_hashkey = GD.GIAO_DICH_HASHKEY
LEFT JOIN khach_hang_sat KH
    ON KH.khach_hang_hashkey = GD.KHACH_HANG_HASHKEY
LEFT JOIN auth_to_chuc_don_vi_active hub_donVi
    ON hub_donVi.business_key = GD.DON_VI_TAO
LEFT JOIN auth_to_chuc_don_vi_sat donVi
    ON donVi.auth_to_chuc_don_vi_hashkey = hub_donVi.auth_to_chuc_don_vi_hashkey
LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.ref_bpm_auth_nhom') NHOM
    ON CAST(GD.VAI_TRO_NGUOI_XL AS STRING) = SPLIT(NHOM.Ref_code, '-')[0]
LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.ref_bpm_danh_muc') luongPD
    ON CAST(TTC.luong_phe_duyet AS STRING) = SPLIT(luongPD.Ref_code, '-')[0]
LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.ref_bpm_danh_muc') trangThai
    ON CAST(GD.TRANG_THAI AS STRING) = SPLIT(trangThai.Ref_code, '-')[0]
LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.ref_bpm_danh_muc') trangThaiHD
    ON CAST(GD.TRANG_THAI_HOAT_DONG AS STRING) = SPLIT(trangThaiHD.Ref_code, '-')[0]
LEFT JOIN giao_dich_ct_user_sat CTGD
    ON CTGD.giao_dich_hashkey = GD.GIAO_DICH_HASHKEY
LEFT JOIN external_transaction_sat EXTR
    ON EXTR.process_id = GD.PROCESS_ID
LEFT JOIN giao_dich_tdcn_tsbd_sat TSBD_ST
    ON TSBD_ST.giao_dich_hashkey = GD.GIAO_DICH_HASHKEY
   AND TSBD_ST.luong_them = 539
LEFT JOIN giao_dich_tdcn_tsbd_sat TSBD_XL
    ON TSBD_XL.giao_dich_hashkey = GD.GIAO_DICH_HASHKEY
   AND TSBD_XL.luong_them = 540
LEFT JOIN IDENTIFIER(:cleaned || '.raw_vault.ref_bpm_danh_muc') dmTSBD
    ON CAST(TSBD_ST.loai_tsbd AS STRING) = SPLIT(dmTSBD.Ref_code, '-')[0]
WHERE (
       TO_DATE(GD.NGAY_TAO)
           > DATE_SUB(
                 TRUNC(TO_DATE(:DATADT, 'yyyyMMdd'), 'YEAR'),
                 1
             )
    OR TO_DATE(GD.NGAY_HOAN_THANH)
           > DATE_SUB(
                 TRUNC(TO_DATE(:DATADT, 'yyyyMMdd'), 'YEAR'),
                 1
             )
)
--GD.QUY_TRINH = 11151;
