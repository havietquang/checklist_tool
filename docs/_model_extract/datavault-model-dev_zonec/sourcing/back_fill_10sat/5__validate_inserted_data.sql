-- =============================================================================
-- VALIDATE INSERTED DATA - Buoc 5
-- Muc dich: Kiem tra toan bo du lieu vua insert vao 10 satellite tables
--
-- Test cases:
--   T1 - NULL CHECK  : Cac cot bat buoc (hashkey, hashdiff, source_event_date,
--                      load_timestamp, record_source) khong duoc NULL
--   T2 - COUNT MATCH : So record deduped tu bronze = so record trong satellite
--                      theo cung date range (du 10 satellites)
--   T3 - LOOKUP      : Khong co record nao tu bronze (sau dedup) bi missing
--                      trong satellite (LEFT ANTI JOIN source -> satellite, du 10 satellites)
--
-- USAGE: Dien dung date range da chay o buoc 2
-- Ket qua mong doi: tat ca overall_result = PASS
-- =============================================================================

DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20230209';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260602';

-- =============================================================================
-- T1: NULL CHECK — 10 satellite tables
-- =============================================================================

DROP TEMPORARY TABLE IF EXISTS tmp_null_check; CREATE TEMPORARY TABLE tmp_null_check AS

SELECT 'sat_categ_entry_audit' AS satellite, COUNT(*) AS null_count
FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_audit
WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd')
  AND (categ_entry_hashkey IS NULL OR hashdiff IS NULL OR source_event_date IS NULL
       OR load_timestamp IS NULL OR record_source IS NULL)

UNION ALL SELECT 'sat_categ_entry_information', COUNT(*)
FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_information
WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd')
  AND (categ_entry_hashkey IS NULL OR hashdiff IS NULL OR source_event_date IS NULL
       OR load_timestamp IS NULL OR record_source IS NULL)

UNION ALL SELECT 'sat_categ_entry_classification', COUNT(*)
FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_classification
WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd')
  AND (categ_entry_hashkey IS NULL OR hashdiff IS NULL OR source_event_date IS NULL
       OR load_timestamp IS NULL OR record_source IS NULL)

UNION ALL SELECT 'sat_re_consol_spec_entry_audit', COUNT(*)
FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_audit
WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd')
  AND (re_consol_spec_entry_hashkey IS NULL OR hashdiff IS NULL OR source_event_date IS NULL
       OR load_timestamp IS NULL OR record_source IS NULL)

UNION ALL SELECT 'sat_re_consol_spec_entry_information', COUNT(*)
FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_information
WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd')
  AND (re_consol_spec_entry_hashkey IS NULL OR hashdiff IS NULL OR source_event_date IS NULL
       OR load_timestamp IS NULL OR record_source IS NULL)

UNION ALL SELECT 'sat_re_consol_spec_entry_classification', COUNT(*)
FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_classification
WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd')
  AND (re_consol_spec_entry_hashkey IS NULL OR hashdiff IS NULL OR source_event_date IS NULL
       OR load_timestamp IS NULL OR record_source IS NULL)

UNION ALL SELECT 'sat_stmt_entry_audit', COUNT(*)
FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_audit
WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd')
  AND (stmt_entry_hashkey IS NULL OR hashdiff IS NULL OR source_event_date IS NULL
       OR load_timestamp IS NULL OR record_source IS NULL)

UNION ALL SELECT 'sat_stmt_entry_information', COUNT(*)
FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_information
WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd')
  AND (stmt_entry_hashkey IS NULL OR hashdiff IS NULL OR source_event_date IS NULL
       OR load_timestamp IS NULL OR record_source IS NULL)

UNION ALL SELECT 'sat_stmt_entry_classification', COUNT(*)
FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_classification
WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd')
  AND (stmt_entry_hashkey IS NULL OR hashdiff IS NULL OR source_event_date IS NULL
       OR load_timestamp IS NULL OR record_source IS NULL)

UNION ALL SELECT 'sat_line_movement_toanhang', COUNT(*)
FROM ocb_datavault_prod_cleaned.raw_vault.sat_line_movement_toanhang
WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd')
  AND (line_movement_toanhang_hashkey IS NULL OR hashdiff IS NULL OR source_event_date IS NULL
       OR load_timestamp IS NULL OR record_source IS NULL);

-- =============================================================================
-- Source temp tables: recompute tất cả 3 hashdiff từ bronze (1 lần scan/source)
-- Dùng cho cả T2 (count) và T3 (lookup) của tất cả 10 satellites
-- =============================================================================

DROP TEMPORARY TABLE IF EXISTS tmp_src_categ; CREATE TEMPORARY TABLE tmp_src_categ AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_inputter        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_authoriser      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_time       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pc_period_end   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_reversal_marker AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_booking_date    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_accounting_date AS string))), ''), 256) AS hd_audit,
    sha2(COALESCE(UPPER(TRIM(CAST(t_currency        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amount_fcy      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amount_lcy      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_value_date      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_narrative       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_trans_reference AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_their_reference AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_our_reference   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_stmt_no         AS string))), ''), 256) AS hd_information,
    sha2(COALESCE(UPPER(TRIM(CAST(t_product_category AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pl_category      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_crf_type         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_system_id        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_transaction_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_consol_key       AS string))), ''), 256) AS hd_classification
FROM ocb_datavault_prod_sourcing.t24.t24_categ_entry
WHERE data_date BETWEEN start_date AND end_date AND id IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_src_reconsol; CREATE TEMPORARY TABLE tmp_src_reconsol AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_reversal_marker AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_record_status   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_curr_no         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_inputter        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_time       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_authoriser      AS string))), ''), 256) AS hd_audit,
    sha2(COALESCE(UPPER(TRIM(CAST(t_amount_lcy      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_narrative       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_value_date      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amount_fcy      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_exchange_rate   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_our_reference   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_local_ref       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_trans_reference AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_booking_date    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_stmt_no         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_currency        AS string))), ''), 256) AS hd_information,
    sha2(COALESCE(UPPER(TRIM(CAST(t_consol_key_type  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pl_category      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_product_category AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_system_id        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_department_code  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_transaction_code AS string))), ''), 256) AS hd_classification
FROM ocb_datavault_prod_sourcing.t24.t24_re_consol_spec_entry
WHERE data_date BETWEEN start_date AND end_date AND id IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_src_stmt; CREATE TEMPORARY TABLE tmp_src_stmt AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_record_status   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_booking_date    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_inputter        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_authoriser      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_processing_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_exposure_date   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_time       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_reversal_marker AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_accounting_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pc_period_end   AS string))), ''), 256) AS hd_audit,
    sha2(COALESCE(UPPER(TRIM(CAST(t_account_number  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amount_lcy      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_their_reference AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_value_date      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amount_fcy      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_exchange_rate   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_our_reference   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_trans_reference AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_currency        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_narrative       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_stmt_no         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_master_account  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_local_ref       AS string))), ''), 256) AS hd_information,
    sha2(COALESCE(UPPER(TRIM(CAST(t_pl_category      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_product_category AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_crf_type         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_system_id        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_transaction_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_department_code  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_consol_key       AS string))), ''), 256) AS hd_classification
FROM ocb_datavault_prod_sourcing.t24.t24_stmt_entry
WHERE data_date BETWEEN start_date AND end_date AND id IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS tmp_src_linemvmt; CREATE TEMPORARY TABLE tmp_src_linemvmt AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(t_line_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_stt     AS string))), ''), 256) AS hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_y_trans_code           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amount_lcy             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amount_fcy             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ccy                    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_consol_key             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_y_xref_rev_marker      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_y_dr_cr                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_y_xref_booking_date    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_y_xref_value_date      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_y_xref_accounting_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_xref_nxt_version       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_stt                    AS string))), ''), 256) AS hashdiff
FROM ocb_datavault_prod_sourcing.t24.t24_line_mvmt_toanhang
WHERE data_date BETWEEN start_date AND end_date
  AND t_line_id IS NOT NULL AND t_stt IS NOT NULL;

-- =============================================================================
-- T2: COUNT MATCH — 10 satellites
-- src_count = số distinct (hashkey, hashdiff) từ bronze
-- sat_count  = số record trong satellite theo date range
-- =============================================================================

DROP TEMPORARY TABLE IF EXISTS tmp_count_check; CREATE TEMPORARY TABLE tmp_count_check AS

SELECT 'sat_categ_entry_audit' AS satellite,
    (SELECT COUNT(*) FROM (SELECT DISTINCT hashkey, hd_audit           FROM tmp_src_categ) t) AS src_count,
    (SELECT COUNT(*) FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_audit
     WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd')) AS sat_count

UNION ALL SELECT 'sat_categ_entry_information',
    (SELECT COUNT(*) FROM (SELECT DISTINCT hashkey, hd_information     FROM tmp_src_categ) t),
    (SELECT COUNT(*) FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_information
     WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd'))

UNION ALL SELECT 'sat_categ_entry_classification',
    (SELECT COUNT(*) FROM (SELECT DISTINCT hashkey, hd_classification  FROM tmp_src_categ) t),
    (SELECT COUNT(*) FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_classification
     WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd'))

UNION ALL SELECT 'sat_re_consol_spec_entry_audit',
    (SELECT COUNT(*) FROM (SELECT DISTINCT hashkey, hd_audit           FROM tmp_src_reconsol) t),
    (SELECT COUNT(*) FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_audit
     WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd'))

UNION ALL SELECT 'sat_re_consol_spec_entry_information',
    (SELECT COUNT(*) FROM (SELECT DISTINCT hashkey, hd_information     FROM tmp_src_reconsol) t),
    (SELECT COUNT(*) FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_information
     WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd'))

UNION ALL SELECT 'sat_re_consol_spec_entry_classification',
    (SELECT COUNT(*) FROM (SELECT DISTINCT hashkey, hd_classification  FROM tmp_src_reconsol) t),
    (SELECT COUNT(*) FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_classification
     WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd'))

UNION ALL SELECT 'sat_stmt_entry_audit',
    (SELECT COUNT(*) FROM (SELECT DISTINCT hashkey, hd_audit           FROM tmp_src_stmt) t),
    (SELECT COUNT(*) FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_audit
     WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd'))

UNION ALL SELECT 'sat_stmt_entry_information',
    (SELECT COUNT(*) FROM (SELECT DISTINCT hashkey, hd_information     FROM tmp_src_stmt) t),
    (SELECT COUNT(*) FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_information
     WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd'))

UNION ALL SELECT 'sat_stmt_entry_classification',
    (SELECT COUNT(*) FROM (SELECT DISTINCT hashkey, hd_classification  FROM tmp_src_stmt) t),
    (SELECT COUNT(*) FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_classification
     WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd'))

UNION ALL SELECT 'sat_line_movement_toanhang',
    (SELECT COUNT(*) FROM (SELECT DISTINCT hashkey, hashdiff           FROM tmp_src_linemvmt) t),
    (SELECT COUNT(*) FROM ocb_datavault_prod_cleaned.raw_vault.sat_line_movement_toanhang
     WHERE source_event_date BETWEEN to_date(start_date,'yyyyMMdd') AND to_date(end_date,'yyyyMMdd'));

-- =============================================================================
-- T3: LOOKUP — bronze LEFT ANTI JOIN satellite — 10 satellites
-- =============================================================================

DROP TEMPORARY TABLE IF EXISTS tmp_missing_check; CREATE TEMPORARY TABLE tmp_missing_check AS

SELECT 'sat_categ_entry_audit' AS satellite, COUNT(*) AS missing_count
FROM (SELECT DISTINCT hashkey, hd_audit          AS hashdiff FROM tmp_src_categ) s
LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_audit t
    ON t.categ_entry_hashkey = s.hashkey AND t.hashdiff = s.hashdiff

UNION ALL SELECT 'sat_categ_entry_information', COUNT(*)
FROM (SELECT DISTINCT hashkey, hd_information    AS hashdiff FROM tmp_src_categ) s
LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_information t
    ON t.categ_entry_hashkey = s.hashkey AND t.hashdiff = s.hashdiff

UNION ALL SELECT 'sat_categ_entry_classification', COUNT(*)
FROM (SELECT DISTINCT hashkey, hd_classification AS hashdiff FROM tmp_src_categ) s
LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_classification t
    ON t.categ_entry_hashkey = s.hashkey AND t.hashdiff = s.hashdiff

UNION ALL SELECT 'sat_re_consol_spec_entry_audit', COUNT(*)
FROM (SELECT DISTINCT hashkey, hd_audit          AS hashdiff FROM tmp_src_reconsol) s
LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_audit t
    ON t.re_consol_spec_entry_hashkey = s.hashkey AND t.hashdiff = s.hashdiff

UNION ALL SELECT 'sat_re_consol_spec_entry_information', COUNT(*)
FROM (SELECT DISTINCT hashkey, hd_information    AS hashdiff FROM tmp_src_reconsol) s
LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_information t
    ON t.re_consol_spec_entry_hashkey = s.hashkey AND t.hashdiff = s.hashdiff

UNION ALL SELECT 'sat_re_consol_spec_entry_classification', COUNT(*)
FROM (SELECT DISTINCT hashkey, hd_classification AS hashdiff FROM tmp_src_reconsol) s
LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_classification t
    ON t.re_consol_spec_entry_hashkey = s.hashkey AND t.hashdiff = s.hashdiff

UNION ALL SELECT 'sat_stmt_entry_audit', COUNT(*)
FROM (SELECT DISTINCT hashkey, hd_audit          AS hashdiff FROM tmp_src_stmt) s
LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_audit t
    ON t.stmt_entry_hashkey = s.hashkey AND t.hashdiff = s.hashdiff

UNION ALL SELECT 'sat_stmt_entry_information', COUNT(*)
FROM (SELECT DISTINCT hashkey, hd_information    AS hashdiff FROM tmp_src_stmt) s
LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_information t
    ON t.stmt_entry_hashkey = s.hashkey AND t.hashdiff = s.hashdiff

UNION ALL SELECT 'sat_stmt_entry_classification', COUNT(*)
FROM (SELECT DISTINCT hashkey, hd_classification AS hashdiff FROM tmp_src_stmt) s
LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_classification t
    ON t.stmt_entry_hashkey = s.hashkey AND t.hashdiff = s.hashdiff

UNION ALL SELECT 'sat_line_movement_toanhang', COUNT(*)
FROM (SELECT DISTINCT hashkey, hashdiff FROM tmp_src_linemvmt) s
LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_line_movement_toanhang t
    ON t.line_movement_toanhang_hashkey = s.hashkey AND t.hashdiff = s.hashdiff;

-- =============================================================================
-- KET QUA TONG HOP
-- Mong doi: overall_result = PASS cho tat ca 10 dong
-- =============================================================================

SELECT
    COALESCE(n.satellite, c.satellite, m.satellite)          AS satellite,
    COALESCE(n.null_count, 0)                                AS null_count,
    CASE WHEN COALESCE(n.null_count, 0) = 0
         THEN 'PASS' ELSE 'FAIL' END                         AS t1_null_check,
    c.src_count                                              AS bronze_count,
    c.sat_count                                              AS satellite_count,
    CASE WHEN c.src_count = c.sat_count THEN 'PASS'
         ELSE 'FAIL' END                                     AS t2_count_match,
    m.missing_count                                          AS missing_count,
    CASE WHEN m.missing_count = 0 THEN 'PASS'
         ELSE 'FAIL' END                                     AS t3_lookup,
    CASE WHEN COALESCE(n.null_count, 0) = 0
          AND c.src_count = c.sat_count
          AND m.missing_count = 0
         THEN 'PASS' ELSE 'FAIL' END                         AS overall_result
FROM      tmp_null_check    n
JOIN      tmp_count_check   c ON c.satellite = n.satellite
JOIN      tmp_missing_check m ON m.satellite = n.satellite
ORDER BY satellite;

-- Cleanup
DROP TEMPORARY TABLE IF EXISTS tmp_null_check;
DROP TEMPORARY TABLE IF EXISTS tmp_src_categ;
DROP TEMPORARY TABLE IF EXISTS tmp_src_reconsol;
DROP TEMPORARY TABLE IF EXISTS tmp_src_stmt;
DROP TEMPORARY TABLE IF EXISTS tmp_src_linemvmt;
DROP TEMPORARY TABLE IF EXISTS tmp_count_check;
DROP TEMPORARY TABLE IF EXISTS tmp_missing_check;
