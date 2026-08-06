-- Source: .t24.t24_ocbh_scm_extra_info
-- Target: :catalog_cleaned.raw_vault
--   hub_security, sts_hub_security_scm_extra_info, sat_scm_extra_info
-- Phase2 addition: priority 2 source.
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_ocbh_scm_extra_info; CREATE TEMPORARY TABLE tmp_t24_ocbh_scm_extra_info AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS security_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_ftp_int_rate_tp AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ftp_int_chg_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ftp_nd_term_int AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ftp_fee_repaid AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ftp_description AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ocb_ftp_bd_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ocb_ftp_callput AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ocb_ftp_frdate AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ocb_ftp_tright AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ocb_ftp_vlpaper AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ocb_ftp_cifcoll AS string))), ''), 256) AS hd_scm_extra_info,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_ftp_int_rate_tp, t_ftp_int_chg_date, t_ftp_nd_term_int, t_ftp_fee_repaid, t_ftp_description,
    t_ocb_ftp_bd_type, t_ocb_ftp_callput, t_ocb_ftp_frdate, t_ocb_ftp_tright, t_ocb_ftp_vlpaper, t_ocb_ftp_cifcoll
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_ocbh_scm_extra_info')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [hub_security] Moved to t24_security_position.sql (consolidated UNION ALL to avoid Delta version conflicts)
-- [sts_hub_security_scm_extra_info] Moved to t24_security_position.sql (hub_security must exist before computing sts)

-- [sat_scm_extra_info] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_scm_extra_info')
(security_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_ftp_int_rate_tp, t_ftp_int_chg_date, t_ftp_nd_term_int, t_ftp_fee_repaid, t_ftp_description,
 t_ocb_ftp_bd_type, t_ocb_ftp_callput, t_ocb_ftp_frdate, t_ocb_ftp_tright, t_ocb_ftp_vlpaper, t_ocb_ftp_cifcoll)
WITH last_known AS (
    SELECT security_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_scm_extra_info')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY security_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_scm_extra_info) OVER (PARTITION BY s.security_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_ocbh_scm_extra_info s
    LEFT JOIN last_known lk ON lk.security_hashkey = s.security_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_scm_extra_info != prev_hashdiff)
SELECT d.security_hashkey, d.hd_scm_extra_info, d.source_event_date, current_timestamp(), 't24__t24_ocbh_scm_extra_info',
       d.t_ftp_int_rate_tp, d.t_ftp_int_chg_date, d.t_ftp_nd_term_int, d.t_ftp_fee_repaid, d.t_ftp_description,
       d.t_ocb_ftp_bd_type, d.t_ocb_ftp_callput, d.t_ocb_ftp_frdate, d.t_ocb_ftp_tright, d.t_ocb_ftp_vlpaper, d.t_ocb_ftp_cifcoll
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_scm_extra_info') t ON t.security_hashkey = d.security_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_ocbh_scm_extra_info;
