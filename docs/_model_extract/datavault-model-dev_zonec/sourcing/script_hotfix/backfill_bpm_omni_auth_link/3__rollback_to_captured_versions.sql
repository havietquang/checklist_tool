-- =============================================================================
-- ROLLBACK: Restore tables ve version da capture o buoc 1
-- Dien version number lay tu 1__pre_run_capture_versions.sql
-- =============================================================================

-- Option A: Rollback theo VERSION
DECLARE OR REPLACE VARIABLE ts_hub    BIGINT DEFAULT 0; -- TODO: hub_auth_nhan_vien version
DECLARE OR REPLACE VARIABLE ts_sat    BIGINT DEFAULT 0; -- TODO: sat_auth_nhan_vien version
DECLARE OR REPLACE VARIABLE ts_lnv    BIGINT DEFAULT 0; -- TODO: link_khach_hang_nhan_vien version
DECLARE OR REPLACE VARIABLE ts_lomni  BIGINT DEFAULT 0; -- TODO: link_omni_user_customer version

EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.hub_auth_nhan_vien        TO VERSION AS OF ', ts_hub);
EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_auth_nhan_vien        TO VERSION AS OF ', ts_sat);
EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.link_khach_hang_nhan_vien TO VERSION AS OF ', ts_lnv);
EXECUTE IMMEDIATE CONCAT('RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.link_omni_user_customer   TO VERSION AS OF ', ts_lomni);

-- Option B: Rollback theo TIMESTAMP (thay the neu khong ghi duoc version)
-- RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.hub_auth_nhan_vien        TO TIMESTAMP AS OF '<YYYY-MM-DD HH:MM:SS>';
-- RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.sat_auth_nhan_vien        TO TIMESTAMP AS OF '<YYYY-MM-DD HH:MM:SS>';
-- RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.link_khach_hang_nhan_vien TO TIMESTAMP AS OF '<YYYY-MM-DD HH:MM:SS>';
-- RESTORE TABLE ocb_datavault_prod_cleaned.raw_vault.link_omni_user_customer   TO TIMESTAMP AS OF '<YYYY-MM-DD HH:MM:SS>';
