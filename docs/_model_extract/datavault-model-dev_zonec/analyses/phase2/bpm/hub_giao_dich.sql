-- Source: bpm (multi-source hub) | Target: hub_giao_dich
-- Gop tat ca nguon insert vao hub_giao_dich thanh 1 script: union all + dedup theo source_priority (giong model hub_giao_dich)
-- Luu y: nguon priority-1 'giao_dich' khong co script init nen khong gop o day.
DROP TEMPORARY TABLE IF EXISTS v_src_hub_giao_dich;
CREATE TEMPORARY TABLE v_src_hub_giao_dich AS
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
        'bpm__giao_dich_the' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.giao_dich_the')
    WHERE gd_id IS NOT NULL
    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        to_date(DATADATE, 'yyyyMMdd') AS source_event_date,
        'bpm__lich_su_giao_dich' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.lich_su_giao_dich')
    WHERE DATADATE BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL
    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(ma_giao_dich AS string))), ''), 256) AS giao_dich_hashkey,
        CAST(ma_giao_dich AS string) AS business_key,
        to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
        'bpm__tc_stk_lich_su' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tc_stk_lich_su')
    WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND ma_giao_dich IS NOT NULL
    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(ma_giao_dich AS string))), ''), 256) AS giao_dich_hashkey,
        CAST(ma_giao_dich AS string) AS business_key,
        to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
        'bpm__tc_stk_thong_tin_tong_hop' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tc_stk_thong_tin_tong_hop')
    WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND ma_giao_dich IS NOT NULL
    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
        'bpm__tcstk_thong_tin_bao_dam' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tcstk_thong_tin_bao_dam')
    WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL
    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
        'bpm__tcstk_thong_tin_chung' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tcstk_thong_tin_chung')
    WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL
    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
        'bpm__tcstk_thong_tin_giao_dich' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tcstk_thong_tin_giao_dich')
    WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL
    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
        'bpm__tdcn_chi_tiet_san_pham' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tdcn_chi_tiet_san_pham')
    WHERE gd_id IS NOT NULL
    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
        'bpm__tdcn_khoan_cap_td_the' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tdcn_khoan_cap_td_the')
    WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL
    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
        'bpm__tdcn_nguoi_dong_vay' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tdcn_nguoi_dong_vay')
    WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL
    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
        'bpm__tdcn_sp_nhu_cau_td' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tdcn_sp_nhu_cau_td')
    WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL
    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
        'bpm__tdcn_thu_nhap_tra_no' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.tdcn_thu_nhap_tra_no')
    WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL
    UNION ALL

    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(gd_id AS string))), ''), 256) AS giao_dich_hashkey,
        CAST(gd_id AS string) AS business_key,
        to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss') AS source_event_date,
        'bpm__ttd_giao_dich_igen' AS record_source,
        2 AS source_priority
    FROM IDENTIFIER({{catalog_sourcing}} || '.bpm.ttd_giao_dich_igen')
    WHERE date_format(to_date(NGAY_TAO, 'yyyy-MM-dd HH:mm:ss'), 'yyyyMMdd') BETWEEN {{start_date}} AND {{end_date}} AND gd_id IS NOT NULL
;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_giao_dich')
(giao_dich_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (
    SELECT
        giao_dich_hashkey, business_key, source_event_date, record_source,
        row_number() OVER (PARTITION BY giao_dich_hashkey ORDER BY source_priority) AS rn
    FROM v_src_hub_giao_dich
    WHERE business_key IS NOT NULL AND trim(CAST(business_key AS string)) <> ''
)
SELECT d.giao_dich_hashkey, d.business_key, d.source_event_date, current_timestamp(), d.record_source
FROM (SELECT * FROM deduped WHERE rn = 1) d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_giao_dich') t
    ON t.giao_dich_hashkey = d.giao_dich_hashkey;
