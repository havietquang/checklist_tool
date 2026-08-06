-- ============================================================
-- Source table  : .crm.crm_contact_type
-- Target tables : ref_crm_contact_type
-- Date range    : fullload {{start_date}}=20250101
-- ============================================================

DROP TEMPORARY TABLE IF EXISTS tmp_crm_contact_type; CREATE TEMPORARY TABLE tmp_crm_contact_type AS
SELECT
    contact_type_id, contact_type_name, status, position, kh_denhan_bh,
    kh_cosp_dexuat, kh_roibo, hd_tiengui_denhan, sn_khachhang, kh_hienhuu,
    taikichhoat, kh_expiredcard, chbh_ganden, cust_group, iscall
FROM IDENTIFIER({{catalog_sourcing}} || '.crm.crm_contact_type')
WHERE contact_type_id IS NOT NULL;

INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_crm_contact_type')
(Ref_hashkey, Ref_type, Ref_code, Ref_description, status, position, kh_denhan_bh, kh_cosp_dexuat,
 kh_roibo, hd_tiengui_denhan, sn_khachhang, kh_hienhuu, taikichhoat, kh_expiredcard,
 chbh_ganden, cust_group, iscall, hashdiff_full, source_event_date, Record_source, load_timestamp)
WITH src AS (
    SELECT
        sha2(('crm_contact_type' || CAST(contact_type_id AS string)), 256) AS Ref_hashkey,
        'crm_contact_type' AS Ref_type,
        CAST(contact_type_id AS string) AS Ref_code,
        CAST(contact_type_name AS string) AS Ref_description,
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
        sha2(COALESCE(UPPER(TRIM(CAST(contact_type_id   AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(contact_type_name AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(status            AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(position          AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(kh_denhan_bh      AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(kh_cosp_dexuat    AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(kh_roibo          AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(hd_tiengui_denhan AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(sn_khachhang      AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(kh_hienhuu        AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(taikichhoat       AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(kh_expiredcard    AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(chbh_ganden       AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(cust_group        AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(iscall            AS string))), ''), 256) AS hashdiff_full,
        to_date({{start_date}}, 'yyyyMMdd') AS source_event_date
    FROM tmp_crm_contact_type
    WHERE contact_type_id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY contact_type_id ORDER BY 1) = 1
)
SELECT
    d.Ref_hashkey AS Ref_hashkey,
    d.Ref_type AS Ref_type,
    d.Ref_code AS Ref_code,
    d.Ref_description AS Ref_description,
    d.status AS status,
    d.position AS position,
    d.kh_denhan_bh AS kh_denhan_bh,
    d.kh_cosp_dexuat AS kh_cosp_dexuat,
    d.kh_roibo AS kh_roibo,
    d.hd_tiengui_denhan AS hd_tiengui_denhan,
    d.sn_khachhang AS sn_khachhang,
    d.kh_hienhuu AS kh_hienhuu,
    d.taikichhoat AS taikichhoat,
    d.kh_expiredcard AS kh_expiredcard,
    d.chbh_ganden AS chbh_ganden,
    d.cust_group AS cust_group,
    d.iscall AS iscall,
    d.hashdiff_full AS hashdiff_full,
    d.source_event_date AS source_event_date,
    'crm__crm_contact_type' AS Record_source,
    current_timestamp() AS load_timestamp
FROM src d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_crm_contact_type') t
    ON t.Ref_hashkey = d.Ref_hashkey AND t.hashdiff_full = d.hashdiff_full;

DROP TEMPORARY TABLE IF EXISTS tmp_crm_contact_type;
