-- =============================================================================
-- Dedup Hub Tables — 3-Step với TEMP TABLE (tự xóa sau mỗi block)
-- Step 1: Tạo TEMP TABLE chứa toàn bộ rows của hashkey dup
-- Step 2: DELETE tất cả rows của hashkey dup khỏi table chính
-- Step 3: INSERT lại 1 row tốt nhất từ temp table (ORDER BY source_event_date, load_timestamp ASC)
-- Verify : kiểm tra không còn dup
-- Drop   : xóa temp table
-- =============================================================================


-- =============================================================================
-- [OMNI] hub_onboarding — 3 dups
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_hub_onboarding
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.hub_onboarding
WHERE onboarding_hashkey IN (
    SELECT onboarding_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.hub_onboarding
    GROUP BY onboarding_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.hub_onboarding
WHERE onboarding_hashkey IN (SELECT DISTINCT onboarding_hashkey FROM tmp_hub_onboarding);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.hub_onboarding
    (onboarding_hashkey, business_key, source_event_date, record_source, load_timestamp)
SELECT onboarding_hashkey, business_key, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY onboarding_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_hub_onboarding
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT onboarding_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.hub_onboarding
WHERE onboarding_hashkey IN (SELECT DISTINCT onboarding_hashkey FROM tmp_hub_onboarding)
GROUP BY onboarding_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_hub_onboarding;


-- =============================================================================
-- [OMNI] hub_payment_order — 58 dups (chưa dùng data_date → duplicate)
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_hub_payment_order
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.hub_payment_order
WHERE payment_order_hashkey IN (
    SELECT payment_order_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.hub_payment_order
    GROUP BY payment_order_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.hub_payment_order
WHERE payment_order_hashkey IN (SELECT DISTINCT payment_order_hashkey FROM tmp_hub_payment_order);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.hub_payment_order
    (payment_order_hashkey, business_key, source_event_date, record_source, load_timestamp)
SELECT payment_order_hashkey, business_key, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY payment_order_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_hub_payment_order
) WHERE _rn = 1;

SELECT payment_order_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.hub_payment_order
WHERE payment_order_hashkey IN (SELECT DISTINCT payment_order_hashkey FROM tmp_hub_payment_order)
GROUP BY payment_order_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_hub_payment_order;


-- =============================================================================
-- [Way4] hub_entry — 9 dups (lỗi file nguồn thừa)
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_hub_entry
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.hub_entry
WHERE entry_hashkey IN (
    SELECT entry_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.hub_entry
    GROUP BY entry_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.hub_entry
WHERE entry_hashkey IN (SELECT DISTINCT entry_hashkey FROM tmp_hub_entry);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.hub_entry
    (entry_hashkey, business_key, source_event_date, record_source, load_timestamp)
SELECT entry_hashkey, business_key, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY entry_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_hub_entry
) WHERE _rn = 1;

SELECT entry_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.hub_entry
WHERE entry_hashkey IN (SELECT DISTINCT entry_hashkey FROM tmp_hub_entry)
GROUP BY entry_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_hub_entry;


-- =============================================================================
-- [T24] hub_consolidate_profit_n_loss — 21924 dups (ngày 20210924)
-- NOTE: Pilot không có lỗi này đến ngày 20260604 → chỉ chạy trên prod
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_hub_consolidate_profit_n_loss
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.hub_consolidate_profit_n_loss
WHERE consolidate_profit_n_loss_hashkey IN (
    SELECT consolidate_profit_n_loss_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.hub_consolidate_profit_n_loss
    GROUP BY consolidate_profit_n_loss_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.hub_consolidate_profit_n_loss
WHERE consolidate_profit_n_loss_hashkey IN (SELECT DISTINCT consolidate_profit_n_loss_hashkey FROM tmp_hub_consolidate_profit_n_loss);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.hub_consolidate_profit_n_loss
    (consolidate_profit_n_loss_hashkey, business_key, source_event_date, record_source, load_timestamp)
SELECT consolidate_profit_n_loss_hashkey, business_key, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY consolidate_profit_n_loss_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_hub_consolidate_profit_n_loss
) WHERE _rn = 1;

SELECT consolidate_profit_n_loss_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.hub_consolidate_profit_n_loss
WHERE consolidate_profit_n_loss_hashkey IN (SELECT DISTINCT consolidate_profit_n_loss_hashkey FROM tmp_hub_consolidate_profit_n_loss)
GROUP BY consolidate_profit_n_loss_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_hub_consolidate_profit_n_loss;


-- =============================================================================
-- [T24] hub_customer — 2284 dups (ngày 20240420)
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_hub_customer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.hub_customer
WHERE customer_hashkey IN (
    SELECT customer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.hub_customer
    GROUP BY customer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.hub_customer
WHERE customer_hashkey IN (SELECT DISTINCT customer_hashkey FROM tmp_hub_customer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.hub_customer
    (customer_hashkey, business_key, source_event_date, record_source, load_timestamp)
SELECT customer_hashkey, business_key, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_hub_customer
) WHERE _rn = 1;

SELECT customer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.hub_customer
WHERE customer_hashkey IN (SELECT DISTINCT customer_hashkey FROM tmp_hub_customer)
GROUP BY customer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_hub_customer;


-- =============================================================================
-- [T24] hub_deposits — 18 dups (ngày 20251020 và 20251021)
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_hub_deposits
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.hub_deposits
WHERE deposit_hashkey IN (
    SELECT deposit_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.hub_deposits
    GROUP BY deposit_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.hub_deposits
WHERE deposit_hashkey IN (SELECT DISTINCT deposit_hashkey FROM tmp_hub_deposits);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.hub_deposits
    (deposit_hashkey, business_key, source_event_date, record_source, load_timestamp)
SELECT deposit_hashkey, business_key, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY deposit_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_hub_deposits
) WHERE _rn = 1;

SELECT deposit_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.hub_deposits
WHERE deposit_hashkey IN (SELECT DISTINCT deposit_hashkey FROM tmp_hub_deposits)
GROUP BY deposit_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_hub_deposits;


-- =============================================================================
-- [T24] hub_teller — 1 dup (BizKey viết hoa/thường → cùng hashkey)
-- NOTE: Fix dài hạn = sửa code staging bỏ UPPER cho teller business_key
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_hub_teller
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.hub_teller
WHERE teller_hashkey IN (
    SELECT teller_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.hub_teller
    GROUP BY teller_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.hub_teller
WHERE teller_hashkey IN (SELECT DISTINCT teller_hashkey FROM tmp_hub_teller);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.hub_teller
    (teller_hashkey, business_key, source_event_date, record_source, load_timestamp)
SELECT teller_hashkey, business_key, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY teller_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_hub_teller
) WHERE _rn = 1;

SELECT teller_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.hub_teller
WHERE teller_hashkey IN (SELECT DISTINCT teller_hashkey FROM tmp_hub_teller)
GROUP BY teller_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_hub_teller;


-- =============================================================================
-- [T24] hub_funds_transfer — 1,079,327 dups (T24_funds_transfer dup ngày 20260421)
-- CẢNH BÁO: số dup rất lớn — chạy riêng, giờ thấp tải
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_hub_funds_transfer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.hub_funds_transfer
WHERE funds_transfer_hashkey IN (
    SELECT funds_transfer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.hub_funds_transfer
    GROUP BY funds_transfer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.hub_funds_transfer
WHERE funds_transfer_hashkey IN (SELECT DISTINCT funds_transfer_hashkey FROM tmp_hub_funds_transfer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.hub_funds_transfer
    (funds_transfer_hashkey, business_key, source_event_date, record_source, load_timestamp)
SELECT funds_transfer_hashkey, business_key, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY funds_transfer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_hub_funds_transfer
) WHERE _rn = 1;

SELECT funds_transfer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.hub_funds_transfer
WHERE funds_transfer_hashkey IN (SELECT DISTINCT funds_transfer_hashkey FROM tmp_hub_funds_transfer)
GROUP BY funds_transfer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_hub_funds_transfer;


-- =============================================================================
-- [T24] hub_line_movement_toanhang — 1 dup (LINE.ID header record)
-- Schema: line_movement_toanhang_hashkey, t_line_id, t_stt, source_event_date, record_source, load_timestamp
-- Staging đã fix extra_where="t_line_id <> 'LINE.ID'" → chỉ DELETE record xấu, không cần 3-step
-- =============================================================================
DELETE FROM ocb_datavault_prod_cleaned.raw_vault.hub_line_movement_toanhang
WHERE t_line_id LIKE 'LINE.ID%';

SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.hub_line_movement_toanhang
WHERE t_line_id LIKE 'LINE.ID%';
