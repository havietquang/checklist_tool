-- =============================================================================
-- PRE RUN CAPTURE VERSIONS - Chạy TRƯỚC KHI chạy 3 script song song
-- Mục đích: Lấy Delta version hiện tại của 10 satellite tables
--
-- USAGE:
--   1. Chạy câu SQL bên dưới
--   2. Copy kết quả (satellite + delta_version)
--   3. Điền vào DECLARE variables trong 4__rollback_to_captured_versions.sql
--
-- NOTE: DESCRIBE HISTORY là command-level statement, không dùng được trong UNION ALL
--       → dùng TEMP TABLE + INSERT riêng từng bảng
-- =============================================================================

DROP TEMPORARY TABLE IF EXISTS tmp_versions; CREATE TEMPORARY TABLE tmp_versions (
    satellite       STRING,
    delta_version   BIGINT,
    delta_timestamp TIMESTAMP,
    operation       STRING
);

INSERT INTO tmp_versions
SELECT 'sat_categ_entry_audit', version, timestamp, operation
FROM (DESCRIBE HISTORY ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_audit) LIMIT 1;

INSERT INTO tmp_versions
SELECT 'sat_categ_entry_information', version, timestamp, operation
FROM (DESCRIBE HISTORY ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_information) LIMIT 1;

INSERT INTO tmp_versions
SELECT 'sat_categ_entry_classification', version, timestamp, operation
FROM (DESCRIBE HISTORY ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_classification) LIMIT 1;

INSERT INTO tmp_versions
SELECT 'sat_re_consol_spec_entry_audit', version, timestamp, operation
FROM (DESCRIBE HISTORY ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_audit) LIMIT 1;

INSERT INTO tmp_versions
SELECT 'sat_re_consol_spec_entry_information', version, timestamp, operation
FROM (DESCRIBE HISTORY ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_information) LIMIT 1;

INSERT INTO tmp_versions
SELECT 'sat_re_consol_spec_entry_classification', version, timestamp, operation
FROM (DESCRIBE HISTORY ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_classification) LIMIT 1;

INSERT INTO tmp_versions
SELECT 'sat_stmt_entry_audit', version, timestamp, operation
FROM (DESCRIBE HISTORY ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_audit) LIMIT 1;

INSERT INTO tmp_versions
SELECT 'sat_stmt_entry_information', version, timestamp, operation
FROM (DESCRIBE HISTORY ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_information) LIMIT 1;

INSERT INTO tmp_versions
SELECT 'sat_stmt_entry_classification', version, timestamp, operation
FROM (DESCRIBE HISTORY ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_classification) LIMIT 1;

INSERT INTO tmp_versions
SELECT 'sat_line_movement_toanhang', version, timestamp, operation
FROM (DESCRIBE HISTORY ocb_datavault_prod_cleaned.raw_vault.sat_line_movement_toanhang) LIMIT 1;

SELECT * FROM tmp_versions ORDER BY satellite;

DROP TEMPORARY TABLE IF EXISTS tmp_versions;
