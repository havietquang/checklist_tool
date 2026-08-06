-- =============================================================================
-- Dedup Satellite Tables — 3-Step với TEMP TABLE (tự xóa sau mỗi block)
-- Unique key của sat: (hashkey, hashdiff, source_event_date)
-- Step 1: Tạo TEMP TABLE chứa toàn bộ rows của composite key dup
-- Step 2: DELETE tất cả rows của composite key dup khỏi table chính
-- Step 3: INSERT lại 1 row tốt nhất từ temp table (ORDER BY load_timestamp ASC)
-- Verify : kiểm tra không còn dup
-- Drop   : xóa temp table
-- NOTE  : DELETE dùng EXISTS thay vì multi-column IN (Delta không hỗ trợ)
-- =============================================================================


-- =============================================================================
-- [T24] sat_categ_entry_audit — 532953 dups
-- Nguồn Duplicated: stg sai ngày 20260606 do hub bị block nhưng đã chạy sat
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_categ_entry_audit
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_audit
WHERE (categ_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT categ_entry_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_audit
    GROUP BY categ_entry_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_audit AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_categ_entry_audit
    WHERE tmp_sat_categ_entry_audit.categ_entry_hashkey = t.categ_entry_hashkey
      AND tmp_sat_categ_entry_audit.hashdiff = t.hashdiff
      AND tmp_sat_categ_entry_audit.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_audit
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY categ_entry_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_categ_entry_audit
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT categ_entry_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_audit
WHERE (categ_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT categ_entry_hashkey, hashdiff, source_event_date FROM tmp_sat_categ_entry_audit
)
GROUP BY categ_entry_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_categ_entry_audit;


-- =============================================================================
-- [T24] sat_categ_entry_classification — 532953 dups
-- Nguồn Duplicated: stg sai ngày 20260606 do hub bị block nhưng đã chạy sat
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_categ_entry_classification
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_classification
WHERE (categ_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT categ_entry_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_classification
    GROUP BY categ_entry_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_classification AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_categ_entry_classification
    WHERE tmp_sat_categ_entry_classification.categ_entry_hashkey = t.categ_entry_hashkey
      AND tmp_sat_categ_entry_classification.hashdiff = t.hashdiff
      AND tmp_sat_categ_entry_classification.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_classification
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY categ_entry_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_categ_entry_classification
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT categ_entry_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_classification
WHERE (categ_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT categ_entry_hashkey, hashdiff, source_event_date FROM tmp_sat_categ_entry_classification
)
GROUP BY categ_entry_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_categ_entry_classification;


-- =============================================================================
-- [T24] sat_categ_entry_information — 532953 dups
-- Nguồn Duplicated: stg sai ngày 20260606 do hub bị block nhưng đã chạy sat
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_categ_entry_information
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_information
WHERE (categ_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT categ_entry_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_information
    GROUP BY categ_entry_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_information AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_categ_entry_information
    WHERE tmp_sat_categ_entry_information.categ_entry_hashkey = t.categ_entry_hashkey
      AND tmp_sat_categ_entry_information.hashdiff = t.hashdiff
      AND tmp_sat_categ_entry_information.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_information
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY categ_entry_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_categ_entry_information
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT categ_entry_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_information
WHERE (categ_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT categ_entry_hashkey, hashdiff, source_event_date FROM tmp_sat_categ_entry_information
)
GROUP BY categ_entry_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_categ_entry_information;


-- =============================================================================
-- [T24] sat_consolidate_profit_n_loss_information — 207119 dups
-- Nguồn Duplicated: T24_consolidate ngày 20210924
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_consolidate_profit_n_loss_information
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_consolidate_profit_n_loss_information
WHERE (consolidate_profit_n_loss_hashkey, hashdiff, source_event_date) IN (
    SELECT consolidate_profit_n_loss_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_consolidate_profit_n_loss_information
    GROUP BY consolidate_profit_n_loss_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_consolidate_profit_n_loss_information AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_consolidate_profit_n_loss_information
    WHERE tmp_sat_consolidate_profit_n_loss_information.consolidate_profit_n_loss_hashkey = t.consolidate_profit_n_loss_hashkey
      AND tmp_sat_consolidate_profit_n_loss_information.hashdiff = t.hashdiff
      AND tmp_sat_consolidate_profit_n_loss_information.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_consolidate_profit_n_loss_information
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY consolidate_profit_n_loss_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_consolidate_profit_n_loss_information
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT consolidate_profit_n_loss_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_consolidate_profit_n_loss_information
WHERE (consolidate_profit_n_loss_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT consolidate_profit_n_loss_hashkey, hashdiff, source_event_date FROM tmp_sat_consolidate_profit_n_loss_information
)
GROUP BY consolidate_profit_n_loss_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_consolidate_profit_n_loss_information;


-- =============================================================================
-- [T24] sat_customer_classification — 4029 dups
-- Nguồn Duplicated: T24_CUSTOMER ngày 20240420
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_customer_classification
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_classification
WHERE (customer_hashkey, hashdiff, source_event_date) IN (
    SELECT customer_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_classification
    GROUP BY customer_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_classification AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_customer_classification
    WHERE tmp_sat_customer_classification.customer_hashkey = t.customer_hashkey
      AND tmp_sat_customer_classification.hashdiff = t.hashdiff
      AND tmp_sat_customer_classification.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_customer_classification
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_customer_classification
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT customer_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_classification
WHERE (customer_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT customer_hashkey, hashdiff, source_event_date FROM tmp_sat_customer_classification
)
GROUP BY customer_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_customer_classification;


-- =============================================================================
-- [T24] sat_customer_contact — 2401 dups
-- Nguồn Duplicated: T24_CUSTOMER ngày 20240420
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_customer_contact
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_contact
WHERE (customer_hashkey, hashdiff, source_event_date) IN (
    SELECT customer_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_contact
    GROUP BY customer_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_contact AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_customer_contact
    WHERE tmp_sat_customer_contact.customer_hashkey = t.customer_hashkey
      AND tmp_sat_customer_contact.hashdiff = t.hashdiff
      AND tmp_sat_customer_contact.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_customer_contact
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_customer_contact
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT customer_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_contact
WHERE (customer_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT customer_hashkey, hashdiff, source_event_date FROM tmp_sat_customer_contact
)
GROUP BY customer_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_customer_contact;


-- =============================================================================
-- [T24] sat_customer_financial_statement — 2352 dups
-- Nguồn Duplicated: T24_CUSTOMER ngày 20240420
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_customer_financial_statement
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_financial_statement
WHERE (customer_hashkey, hashdiff, source_event_date) IN (
    SELECT customer_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_financial_statement
    GROUP BY customer_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_financial_statement AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_customer_financial_statement
    WHERE tmp_sat_customer_financial_statement.customer_hashkey = t.customer_hashkey
      AND tmp_sat_customer_financial_statement.hashdiff = t.hashdiff
      AND tmp_sat_customer_financial_statement.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_customer_financial_statement
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_customer_financial_statement
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT customer_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_financial_statement
WHERE (customer_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT customer_hashkey, hashdiff, source_event_date FROM tmp_sat_customer_financial_statement
)
GROUP BY customer_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_customer_financial_statement;


-- =============================================================================
-- [T24] sat_customer_information — 2709 dups
-- Nguồn Duplicated: T24_CUSTOMER ngày 20240420
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_customer_information
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_information
WHERE (customer_hashkey, hashdiff, source_event_date) IN (
    SELECT customer_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_information
    GROUP BY customer_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_information AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_customer_information
    WHERE tmp_sat_customer_information.customer_hashkey = t.customer_hashkey
      AND tmp_sat_customer_information.hashdiff = t.hashdiff
      AND tmp_sat_customer_information.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_customer_information
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_customer_information
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT customer_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_information
WHERE (customer_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT customer_hashkey, hashdiff, source_event_date FROM tmp_sat_customer_information
)
GROUP BY customer_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_customer_information;


-- =============================================================================
-- [T24] sat_customer_kyc — 2432 dups
-- Nguồn Duplicated: T24_CUSTOMER ngày 20240420
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_customer_kyc
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_kyc
WHERE (customer_hashkey, hashdiff, source_event_date) IN (
    SELECT customer_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_kyc
    GROUP BY customer_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_kyc AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_customer_kyc
    WHERE tmp_sat_customer_kyc.customer_hashkey = t.customer_hashkey
      AND tmp_sat_customer_kyc.hashdiff = t.hashdiff
      AND tmp_sat_customer_kyc.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_customer_kyc
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_customer_kyc
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT customer_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_kyc
WHERE (customer_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT customer_hashkey, hashdiff, source_event_date FROM tmp_sat_customer_kyc
)
GROUP BY customer_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_customer_kyc;


-- =============================================================================
-- [T24] sat_customer_other — 2595 dups
-- Nguồn Duplicated: T24_CUSTOMER ngày 20240420
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_customer_other
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_other
WHERE (customer_hashkey, hashdiff, source_event_date) IN (
    SELECT customer_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_other
    GROUP BY customer_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_other AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_customer_other
    WHERE tmp_sat_customer_other.customer_hashkey = t.customer_hashkey
      AND tmp_sat_customer_other.hashdiff = t.hashdiff
      AND tmp_sat_customer_other.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_customer_other
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_customer_other
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT customer_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_customer_other
WHERE (customer_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT customer_hashkey, hashdiff, source_event_date FROM tmp_sat_customer_other
)
GROUP BY customer_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_customer_other;


-- =============================================================================
-- [T24] sat_deposits_classification — 18 dups
-- Nguồn Duplicated: T24 az account
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_deposits_classification
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_classification
WHERE (deposit_hashkey, hashdiff, source_event_date) IN (
    SELECT deposit_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_classification
    GROUP BY deposit_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_classification AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_deposits_classification
    WHERE tmp_sat_deposits_classification.deposit_hashkey = t.deposit_hashkey
      AND tmp_sat_deposits_classification.hashdiff = t.hashdiff
      AND tmp_sat_deposits_classification.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_deposits_classification
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY deposit_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_deposits_classification
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT deposit_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_classification
WHERE (deposit_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT deposit_hashkey, hashdiff, source_event_date FROM tmp_sat_deposits_classification
)
GROUP BY deposit_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_deposits_classification;


-- =============================================================================
-- [T24] sat_deposits_ftp — 18 dups
-- Nguồn Duplicated: T24 az account
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_deposits_ftp
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_ftp
WHERE (deposit_hashkey, hashdiff, source_event_date) IN (
    SELECT deposit_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_ftp
    GROUP BY deposit_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_ftp AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_deposits_ftp
    WHERE tmp_sat_deposits_ftp.deposit_hashkey = t.deposit_hashkey
      AND tmp_sat_deposits_ftp.hashdiff = t.hashdiff
      AND tmp_sat_deposits_ftp.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_deposits_ftp
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY deposit_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_deposits_ftp
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT deposit_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_ftp
WHERE (deposit_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT deposit_hashkey, hashdiff, source_event_date FROM tmp_sat_deposits_ftp
)
GROUP BY deposit_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_deposits_ftp;


-- =============================================================================
-- [T24] sat_deposits_information — 22 dups
-- Nguồn Duplicated: T24 az account
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_deposits_information
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_information
WHERE (deposit_hashkey, hashdiff, source_event_date) IN (
    SELECT deposit_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_information
    GROUP BY deposit_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_information AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_deposits_information
    WHERE tmp_sat_deposits_information.deposit_hashkey = t.deposit_hashkey
      AND tmp_sat_deposits_information.hashdiff = t.hashdiff
      AND tmp_sat_deposits_information.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_deposits_information
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY deposit_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_deposits_information
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT deposit_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_information
WHERE (deposit_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT deposit_hashkey, hashdiff, source_event_date FROM tmp_sat_deposits_information
)
GROUP BY deposit_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_deposits_information;


-- =============================================================================
-- [T24] sat_deposits_rate — 20 dups
-- Nguồn Duplicated: T24 az account
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_deposits_rate
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_rate
WHERE (deposit_hashkey, hashdiff, source_event_date) IN (
    SELECT deposit_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_rate
    GROUP BY deposit_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_rate AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_deposits_rate
    WHERE tmp_sat_deposits_rate.deposit_hashkey = t.deposit_hashkey
      AND tmp_sat_deposits_rate.hashdiff = t.hashdiff
      AND tmp_sat_deposits_rate.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_deposits_rate
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY deposit_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_deposits_rate
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT deposit_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_rate
WHERE (deposit_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT deposit_hashkey, hashdiff, source_event_date FROM tmp_sat_deposits_rate
)
GROUP BY deposit_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_deposits_rate;


-- =============================================================================
-- [T24] sat_deposits_system — 22 dups
-- Nguồn Duplicated: T24 az account
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_deposits_system
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_system
WHERE (deposit_hashkey, hashdiff, source_event_date) IN (
    SELECT deposit_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_system
    GROUP BY deposit_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_system AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_deposits_system
    WHERE tmp_sat_deposits_system.deposit_hashkey = t.deposit_hashkey
      AND tmp_sat_deposits_system.hashdiff = t.hashdiff
      AND tmp_sat_deposits_system.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_deposits_system
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY deposit_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_deposits_system
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT deposit_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_system
WHERE (deposit_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT deposit_hashkey, hashdiff, source_event_date FROM tmp_sat_deposits_system
)
GROUP BY deposit_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_deposits_system;


-- =============================================================================
-- [T24] sat_deposits_terms — 18 dups
-- Nguồn Duplicated: T24 az account
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_deposits_terms
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_terms
WHERE (deposit_hashkey, hashdiff, source_event_date) IN (
    SELECT deposit_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_terms
    GROUP BY deposit_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_terms AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_deposits_terms
    WHERE tmp_sat_deposits_terms.deposit_hashkey = t.deposit_hashkey
      AND tmp_sat_deposits_terms.hashdiff = t.hashdiff
      AND tmp_sat_deposits_terms.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_deposits_terms
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY deposit_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_deposits_terms
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT deposit_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_deposits_terms
WHERE (deposit_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT deposit_hashkey, hashdiff, source_event_date FROM tmp_sat_deposits_terms
)
GROUP BY deposit_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_deposits_terms;


-- =============================================================================
-- [WAY4] sat_document_identifiers — 19 dòng thừa
-- Code Error: sai script init
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_document_identifiers
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_document_identifiers
WHERE (document_hashkey, hashdiff, source_event_date) IN (
    SELECT document_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_document_identifiers
    GROUP BY document_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_document_identifiers AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_document_identifiers
    WHERE tmp_sat_document_identifiers.document_hashkey = t.document_hashkey
      AND tmp_sat_document_identifiers.hashdiff = t.hashdiff
      AND tmp_sat_document_identifiers.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_document_identifiers
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY document_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_document_identifiers
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT document_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_document_identifiers
WHERE (document_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT document_hashkey, hashdiff, source_event_date FROM tmp_sat_document_identifiers
)
GROUP BY document_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_document_identifiers;


-- =============================================================================
-- [WAY4] sat_entry_amount — 9 dups
-- Nguồn duplicate: lỗi nguồn do file nguồn thừa
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_entry_amount
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_entry_amount
WHERE (entry_hashkey, hashdiff, source_event_date) IN (
    SELECT entry_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_entry_amount
    GROUP BY entry_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_entry_amount AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_entry_amount
    WHERE tmp_sat_entry_amount.entry_hashkey = t.entry_hashkey
      AND tmp_sat_entry_amount.hashdiff = t.hashdiff
      AND tmp_sat_entry_amount.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_entry_amount
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY entry_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_entry_amount
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT entry_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_entry_amount
WHERE (entry_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT entry_hashkey, hashdiff, source_event_date FROM tmp_sat_entry_amount
)
GROUP BY entry_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_entry_amount;


-- =============================================================================
-- [WAY4] sat_entry_information — 9 dups
-- Nguồn duplicate: lỗi nguồn do file nguồn thừa
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_entry_information
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_entry_information
WHERE (entry_hashkey, hashdiff, source_event_date) IN (
    SELECT entry_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_entry_information
    GROUP BY entry_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_entry_information AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_entry_information
    WHERE tmp_sat_entry_information.entry_hashkey = t.entry_hashkey
      AND tmp_sat_entry_information.hashdiff = t.hashdiff
      AND tmp_sat_entry_information.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_entry_information
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY entry_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_entry_information
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT entry_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_entry_information
WHERE (entry_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT entry_hashkey, hashdiff, source_event_date FROM tmp_sat_entry_information
)
GROUP BY entry_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_entry_information;


-- =============================================================================
-- [OMNI] sat_party_account_information — 28 dups
-- Nguồn duplicate: account_information OMNI
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_party_account_information
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_party_account_information
WHERE (party_hashkey, hashdiff, source_event_date) IN (
    SELECT party_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_party_account_information
    GROUP BY party_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_party_account_information AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_party_account_information
    WHERE tmp_sat_party_account_information.party_hashkey = t.party_hashkey
      AND tmp_sat_party_account_information.hashdiff = t.hashdiff
      AND tmp_sat_party_account_information.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_party_account_information
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY party_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_party_account_information
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT party_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_party_account_information
WHERE (party_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT party_hashkey, hashdiff, source_event_date FROM tmp_sat_party_account_information
)
GROUP BY party_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_party_account_information;


-- =============================================================================
-- [T24] sat_re_consol_spec_entry_audit — 613861/1 dups
-- Nguồn Duplicated: stg sai ngày 20260606 + T24_re_consol_spec_entry dup 20221010
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_re_consol_spec_entry_audit
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_audit
WHERE (re_consol_spec_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT re_consol_spec_entry_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_audit
    GROUP BY re_consol_spec_entry_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_audit AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_re_consol_spec_entry_audit
    WHERE tmp_sat_re_consol_spec_entry_audit.re_consol_spec_entry_hashkey = t.re_consol_spec_entry_hashkey
      AND tmp_sat_re_consol_spec_entry_audit.hashdiff = t.hashdiff
      AND tmp_sat_re_consol_spec_entry_audit.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_audit
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY re_consol_spec_entry_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_re_consol_spec_entry_audit
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT re_consol_spec_entry_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_audit
WHERE (re_consol_spec_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT re_consol_spec_entry_hashkey, hashdiff, source_event_date FROM tmp_sat_re_consol_spec_entry_audit
)
GROUP BY re_consol_spec_entry_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_re_consol_spec_entry_audit;


-- =============================================================================
-- [T24] sat_re_consol_spec_entry_classification — 613861/1 dups
-- Nguồn Duplicated: stg sai ngày 20260606 + T24_re_consol_spec_entry dup 20221010
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_re_consol_spec_entry_classification
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_classification
WHERE (re_consol_spec_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT re_consol_spec_entry_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_classification
    GROUP BY re_consol_spec_entry_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_classification AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_re_consol_spec_entry_classification
    WHERE tmp_sat_re_consol_spec_entry_classification.re_consol_spec_entry_hashkey = t.re_consol_spec_entry_hashkey
      AND tmp_sat_re_consol_spec_entry_classification.hashdiff = t.hashdiff
      AND tmp_sat_re_consol_spec_entry_classification.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_classification
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY re_consol_spec_entry_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_re_consol_spec_entry_classification
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT re_consol_spec_entry_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_classification
WHERE (re_consol_spec_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT re_consol_spec_entry_hashkey, hashdiff, source_event_date FROM tmp_sat_re_consol_spec_entry_classification
)
GROUP BY re_consol_spec_entry_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_re_consol_spec_entry_classification;


-- =============================================================================
-- [T24] sat_re_consol_spec_entry_information — 613861/1 dups
-- Nguồn Duplicated: stg sai ngày 20260606 + T24_re_consol_spec_entry dup 20221010
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_re_consol_spec_entry_information
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_information
WHERE (re_consol_spec_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT re_consol_spec_entry_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_information
    GROUP BY re_consol_spec_entry_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_information AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_re_consol_spec_entry_information
    WHERE tmp_sat_re_consol_spec_entry_information.re_consol_spec_entry_hashkey = t.re_consol_spec_entry_hashkey
      AND tmp_sat_re_consol_spec_entry_information.hashdiff = t.hashdiff
      AND tmp_sat_re_consol_spec_entry_information.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_information
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY re_consol_spec_entry_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_re_consol_spec_entry_information
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT re_consol_spec_entry_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_information
WHERE (re_consol_spec_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT re_consol_spec_entry_hashkey, hashdiff, source_event_date FROM tmp_sat_re_consol_spec_entry_information
)
GROUP BY re_consol_spec_entry_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_re_consol_spec_entry_information;


-- =============================================================================
-- [T24] sat_stmt_entry_audit — 2593119/15328 dups
-- Nguồn Duplicated: stg sai ngày 20260606 + t24_stmt_entry dup 20221010
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_stmt_entry_audit
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_audit
WHERE (stmt_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT stmt_entry_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_audit
    GROUP BY stmt_entry_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_audit AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_stmt_entry_audit
    WHERE tmp_sat_stmt_entry_audit.stmt_entry_hashkey = t.stmt_entry_hashkey
      AND tmp_sat_stmt_entry_audit.hashdiff = t.hashdiff
      AND tmp_sat_stmt_entry_audit.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_audit
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY stmt_entry_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_stmt_entry_audit
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT stmt_entry_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_audit
WHERE (stmt_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT stmt_entry_hashkey, hashdiff, source_event_date FROM tmp_sat_stmt_entry_audit
)
GROUP BY stmt_entry_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_stmt_entry_audit;


-- =============================================================================
-- [T24] sat_stmt_entry_classification — 2593119/15328 dups
-- Nguồn Duplicated: stg sai ngày 20260606 + t24_stmt_entry dup 20221010
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_stmt_entry_classification
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_classification
WHERE (stmt_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT stmt_entry_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_classification
    GROUP BY stmt_entry_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_classification AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_stmt_entry_classification
    WHERE tmp_sat_stmt_entry_classification.stmt_entry_hashkey = t.stmt_entry_hashkey
      AND tmp_sat_stmt_entry_classification.hashdiff = t.hashdiff
      AND tmp_sat_stmt_entry_classification.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_classification
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY stmt_entry_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_stmt_entry_classification
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT stmt_entry_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_classification
WHERE (stmt_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT stmt_entry_hashkey, hashdiff, source_event_date FROM tmp_sat_stmt_entry_classification
)
GROUP BY stmt_entry_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_stmt_entry_classification;


-- =============================================================================
-- [T24] sat_stmt_entry_information — 2593119/15328 dups
-- Nguồn Duplicated: stg sai ngày 20260606 + t24_stmt_entry dup 20221010
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_sat_stmt_entry_information
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_information
WHERE (stmt_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT stmt_entry_hashkey, hashdiff, source_event_date
    FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_information
    GROUP BY stmt_entry_hashkey, hashdiff, source_event_date HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_information AS t
WHERE EXISTS (
    SELECT 1 FROM tmp_sat_stmt_entry_information
    WHERE tmp_sat_stmt_entry_information.stmt_entry_hashkey = t.stmt_entry_hashkey
      AND tmp_sat_stmt_entry_information.hashdiff = t.hashdiff
      AND tmp_sat_stmt_entry_information.source_event_date = t.source_event_date
);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_information
SELECT * EXCEPT(_rn)
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY stmt_entry_hashkey, hashdiff, source_event_date ORDER BY load_timestamp ASC) AS _rn
    FROM tmp_sat_stmt_entry_information
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT stmt_entry_hashkey, hashdiff, source_event_date, COUNT(*) cnt
FROM ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_information
WHERE (stmt_entry_hashkey, hashdiff, source_event_date) IN (
    SELECT DISTINCT stmt_entry_hashkey, hashdiff, source_event_date FROM tmp_sat_stmt_entry_information
)
GROUP BY stmt_entry_hashkey, hashdiff, source_event_date HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_sat_stmt_entry_information;
