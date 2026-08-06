-- =============================================================================
-- ROLLBACK TO CAPTURED VERSIONS - Chạy khi cần hoàn tác
-- Mục đích: Restore 10 satellite tables về đúng Delta version
--           đã lấy từ 1__pre_run_capture_versions.sql
--
-- USAGE:
--   1. Chạy 1__pre_run_capture_versions.sql → copy cột delta_version
--   2. Điền delta_version vào từng DECLARE bên dưới (thay số 0)
--   3. Chạy script này
--
-- LƯU Ý:
--   - Phải rollback trong vòng 7 ngày (Delta retention mặc định)
--   - RESTORE dùng EXECUTE IMMEDIATE vì Databricks không hỗ trợ
--     session variable trực tiếp trong mệnh đề TO VERSION AS OF
--   - RESTORE là DML → Structured Streaming sẽ đọc lại data → tắt
--     streaming job trước khi rollback nếu có
-- =============================================================================

-- !! ĐIỀN delta_version từ output của 1__pre_run_capture_versions.sql !!
DECLARE OR REPLACE VARIABLE v_categ_entry_audit                   BIGINT DEFAULT 0;
DECLARE OR REPLACE VARIABLE v_categ_entry_information             BIGINT DEFAULT 0;
DECLARE OR REPLACE VARIABLE v_categ_entry_classification          BIGINT DEFAULT 0;
DECLARE OR REPLACE VARIABLE v_re_consol_spec_entry_audit          BIGINT DEFAULT 0;
DECLARE OR REPLACE VARIABLE v_re_consol_spec_entry_information    BIGINT DEFAULT 0;
DECLARE OR REPLACE VARIABLE v_re_consol_spec_entry_classification BIGINT DEFAULT 0;
DECLARE OR REPLACE VARIABLE v_stmt_entry_audit                    BIGINT DEFAULT 0;
DECLARE OR REPLACE VARIABLE v_stmt_entry_information              BIGINT DEFAULT 0;
DECLARE OR REPLACE VARIABLE v_stmt_entry_classification           BIGINT DEFAULT 0;
DECLARE OR REPLACE VARIABLE v_line_movement_toanhang              BIGINT DEFAULT 0;

-- =============================================================================
-- RESTORE — EXECUTE IMMEDIATE để truyền session variable vào AS OF
-- =============================================================================

-- =============================================================================
-- OPTION A: ROLLBACK THEO VERSION (chính xác hơn, ưu tiên dùng)
-- Điền delta_version từ output của 1__pre_run_capture_versions.sql
-- =============================================================================

EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_audit                   TO VERSION AS OF ', v_categ_entry_audit);
EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_information             TO VERSION AS OF ', v_categ_entry_information);
EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_classification          TO VERSION AS OF ', v_categ_entry_classification);
EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_audit          TO VERSION AS OF ', v_re_consol_spec_entry_audit);
EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_information    TO VERSION AS OF ', v_re_consol_spec_entry_information);
EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_classification TO VERSION AS OF ', v_re_consol_spec_entry_classification);
EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_audit                    TO VERSION AS OF ', v_stmt_entry_audit);
EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_information              TO VERSION AS OF ', v_stmt_entry_information);
EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_classification           TO VERSION AS OF ', v_stmt_entry_classification);
EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_line_movement_toanhang              TO VERSION AS OF ', v_line_movement_toanhang);

-- =============================================================================
-- OPTION B: ROLLBACK THEO TIMESTAMP (dùng khi không ghi lại version)
-- Điền delta_timestamp từ output của 1__pre_run_capture_versions.sql
-- Format: 'yyyy-MM-dd HH:mm:ss'  (ví dụ: '2026-06-04 08:30:00')
-- Lưu ý: comment toàn bộ DECLARE v_* và EXECUTE IMMEDIATE OPTION A trước khi chạy OPTION B
-- =============================================================================

-- DECLARE OR REPLACE VARIABLE ts_categ_entry_audit                   STRING DEFAULT '1970-01-01 00:00:00';
-- DECLARE OR REPLACE VARIABLE ts_categ_entry_information             STRING DEFAULT '1970-01-01 00:00:00';
-- DECLARE OR REPLACE VARIABLE ts_categ_entry_classification          STRING DEFAULT '1970-01-01 00:00:00';
-- DECLARE OR REPLACE VARIABLE ts_re_consol_spec_entry_audit          STRING DEFAULT '1970-01-01 00:00:00';
-- DECLARE OR REPLACE VARIABLE ts_re_consol_spec_entry_information    STRING DEFAULT '1970-01-01 00:00:00';
-- DECLARE OR REPLACE VARIABLE ts_re_consol_spec_entry_classification STRING DEFAULT '1970-01-01 00:00:00';
-- DECLARE OR REPLACE VARIABLE ts_stmt_entry_audit                    STRING DEFAULT '1970-01-01 00:00:00';
-- DECLARE OR REPLACE VARIABLE ts_stmt_entry_information              STRING DEFAULT '1970-01-01 00:00:00';
-- DECLARE OR REPLACE VARIABLE ts_stmt_entry_classification           STRING DEFAULT '1970-01-01 00:00:00';
-- DECLARE OR REPLACE VARIABLE ts_line_movement_toanhang              STRING DEFAULT '1970-01-01 00:00:00';

-- EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_audit                   TO TIMESTAMP AS OF ''', ts_categ_entry_audit,                   '''');
-- EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_information             TO TIMESTAMP AS OF ''', ts_categ_entry_information,             '''');
-- EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_classification          TO TIMESTAMP AS OF ''', ts_categ_entry_classification,          '''');
-- EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_audit          TO TIMESTAMP AS OF ''', ts_re_consol_spec_entry_audit,          '''');
-- EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_information    TO TIMESTAMP AS OF ''', ts_re_consol_spec_entry_information,    '''');
-- EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_classification TO TIMESTAMP AS OF ''', ts_re_consol_spec_entry_classification, '''');
-- EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_audit                    TO TIMESTAMP AS OF ''', ts_stmt_entry_audit,                    '''');
-- EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_information              TO TIMESTAMP AS OF ''', ts_stmt_entry_information,              '''');
-- EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_classification           TO TIMESTAMP AS OF ''', ts_stmt_entry_classification,           '''');
-- EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_line_movement_toanhang              TO TIMESTAMP AS OF ''', ts_line_movement_toanhang,              '''');
