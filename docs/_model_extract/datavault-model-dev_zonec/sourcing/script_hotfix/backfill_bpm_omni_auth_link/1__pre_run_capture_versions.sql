-- =============================================================================
-- PRE RUN CAPTURE VERSIONS - BPM/OMNI Auth & Link
-- USAGE: Chay script nay -> copy cot delta_version -> dien vao 2a-2d scripts
-- NOTE: DESCRIBE HISTORY khong dung duoc trong UNION ALL
--       -> dung TEMP TABLE + INSERT rieng tung bang
-- =============================================================================

DROP TEMPORARY TABLE IF EXISTS tmp_versions;
CREATE TEMPORARY TABLE tmp_versions (
    table_name      STRING,
    delta_version   BIGINT,
    delta_timestamp TIMESTAMP,
    operation       STRING
);

INSERT INTO tmp_versions SELECT 'hub_auth_nhan_vien',        version, timestamp, operation FROM (DESCRIBE HISTORY ocb_datavault_prod_cleaned.raw_vault.hub_auth_nhan_vien)        LIMIT 1;
INSERT INTO tmp_versions SELECT 'sat_auth_nhan_vien',        version, timestamp, operation FROM (DESCRIBE HISTORY ocb_datavault_prod_cleaned.raw_vault.sat_auth_nhan_vien)        LIMIT 1;
INSERT INTO tmp_versions SELECT 'link_khach_hang_nhan_vien', version, timestamp, operation FROM (DESCRIBE HISTORY ocb_datavault_prod_cleaned.raw_vault.link_khach_hang_nhan_vien) LIMIT 1;
INSERT INTO tmp_versions SELECT 'link_omni_user_customer',   version, timestamp, operation FROM (DESCRIBE HISTORY ocb_datavault_prod_cleaned.raw_vault.link_omni_user_customer)   LIMIT 1;

SELECT * FROM tmp_versions ORDER BY table_name;
