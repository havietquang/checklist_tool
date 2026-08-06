-- ==============================================================================
-- DROP TABLES SCRIPT
-- ==============================================================================

DROP TABLE IF EXISTS ocb_datavault_prod_cleaned.raw_vault.sat_device_omni_information;
DROP TABLE IF EXISTS ocb_datavault_prod_cleaned.raw_vault.sat_device_detail;
DROP TABLE IF EXISTS ocb_datavault_prod_cleaned.raw_vault.sat_onboarding_information;
DROP TABLE IF EXISTS ocb_datavault_prod_cleaned.raw_vault.link_voucher_campaign;
DROP TABLE IF EXISTS ocb_datavault_prod_cleaned.raw_vault.link_voucher_generate_voucher_campaign;
DROP TABLE IF EXISTS ocb_datavault_prod_cleaned.raw_vault.sat_od_registration_agreement;
DROP TABLE IF EXISTS ocb_datavault_prod_cleaned.raw_vault.link_credit_card_registration_bpm;
DROP TABLE IF EXISTS ocb_datavault_prod_cleaned.raw_vault.sat_payment_order_information;
DROP TABLE IF EXISTS ocb_datavault_prod_cleaned.raw_vault.sat_payment_order_schedule;
DROP TABLE IF EXISTS ocb_datavault_prod_cleaned.raw_vault.link_payment_card;
DROP TABLE IF EXISTS ocb_datavault_prod_cleaned.raw_vault.link_collateral_az_account;
DROP TABLE IF EXISTS ocb_datavault_prod_cleaned.raw_vault.sat_collateral_information;
DROP TABLE IF EXISTS ocb_datavault_prod_cleaned.raw_vault.sat_qlns_nguoi_lao_dong_info_don_vi;

-- Xóa cột last_scan khỏi sat_acnt_contract_information
-- Lý do: cột bị loại khỏi model dbt và hashdiff_acnt_contract_information (2026-06-17)
-- Chạy SAU KHI deploy model dbt mới
ALTER TABLE ocb_datavault_prod_cleaned.raw_vault.sat_acnt_contract_information
DROP COLUMN last_scan;
