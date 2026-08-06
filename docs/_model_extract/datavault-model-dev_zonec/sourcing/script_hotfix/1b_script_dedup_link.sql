-- =============================================================================
-- Dedup Link Tables — 3-Step với TEMP TABLE (tự xóa sau mỗi block)
-- Step 1: Tạo TEMP TABLE chứa toàn bộ rows của hashkey dup
-- Step 2: DELETE tất cả rows của hashkey dup khỏi table chính
-- Step 3: INSERT lại 1 row tốt nhất từ temp table (ORDER BY source_event_date, load_timestamp ASC)
-- Verify : kiểm tra không còn dup
-- Drop   : xóa temp table
-- =============================================================================


-- =============================================================================
-- [T24] link_categ_entry_branch — 532953 dups
-- Nguồn Duplicated: v_stg_t24_t24_line_mvmt_toanhang ngày 20260606
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_categ_entry_branch
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_categ_entry_branch
WHERE link_categ_entry_branch_hashkey IN (
    SELECT link_categ_entry_branch_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_categ_entry_branch
    GROUP BY link_categ_entry_branch_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_categ_entry_branch
WHERE link_categ_entry_branch_hashkey IN (SELECT DISTINCT link_categ_entry_branch_hashkey FROM tmp_link_categ_entry_branch);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_categ_entry_branch
    (link_categ_entry_branch_hashkey, categ_entry_hashkey, branch_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_categ_entry_branch_hashkey, categ_entry_hashkey, branch_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_categ_entry_branch_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_categ_entry_branch
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_categ_entry_branch_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_categ_entry_branch
WHERE link_categ_entry_branch_hashkey IN (SELECT DISTINCT link_categ_entry_branch_hashkey FROM tmp_link_categ_entry_branch)
GROUP BY link_categ_entry_branch_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_categ_entry_branch;


-- =============================================================================
-- [T24] link_categ_entry_customer — 532516 dups
-- Nguồn Duplicated: v_stg_t24_t24_line_mvmt_toanhang ngày 20260606
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_categ_entry_customer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_categ_entry_customer
WHERE link_categ_entry_customer_hashkey IN (
    SELECT link_categ_entry_customer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_categ_entry_customer
    GROUP BY link_categ_entry_customer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_categ_entry_customer
WHERE link_categ_entry_customer_hashkey IN (SELECT DISTINCT link_categ_entry_customer_hashkey FROM tmp_link_categ_entry_customer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_categ_entry_customer
    (link_categ_entry_customer_hashkey, categ_entry_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_categ_entry_customer_hashkey, categ_entry_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_categ_entry_customer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_categ_entry_customer
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_categ_entry_customer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_categ_entry_customer
WHERE link_categ_entry_customer_hashkey IN (SELECT DISTINCT link_categ_entry_customer_hashkey FROM tmp_link_categ_entry_customer)
GROUP BY link_categ_entry_customer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_categ_entry_customer;


-- =============================================================================
-- [T24] link_customer_branch — 2284 dups
-- Nguồn Duplicated: T24_CUSTOMER ngày 20240420
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_customer_branch
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_branch
WHERE link_customer_branch_hashkey IN (
    SELECT link_customer_branch_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_branch
    GROUP BY link_customer_branch_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_branch
WHERE link_customer_branch_hashkey IN (SELECT DISTINCT link_customer_branch_hashkey FROM tmp_link_customer_branch);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_customer_branch
    (link_customer_branch_hashkey, customer_hashkey, branch_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_customer_branch_hashkey, customer_hashkey, branch_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_customer_branch_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_customer_branch
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_customer_branch_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_branch
WHERE link_customer_branch_hashkey IN (SELECT DISTINCT link_customer_branch_hashkey FROM tmp_link_customer_branch)
GROUP BY link_customer_branch_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_customer_branch;


-- =============================================================================
-- [T24] link_customer_dept_acct_officer_nvgt — 2293 dups
-- Nguồn Duplicated: T24_CUSTOMER ngày 20240420
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_customer_dept_acct_officer_nvgt
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_dept_acct_officer_nvgt
WHERE link_customer_dept_acct_officer_nvgt_hashkey IN (
    SELECT link_customer_dept_acct_officer_nvgt_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_dept_acct_officer_nvgt
    GROUP BY link_customer_dept_acct_officer_nvgt_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_dept_acct_officer_nvgt
WHERE link_customer_dept_acct_officer_nvgt_hashkey IN (SELECT DISTINCT link_customer_dept_acct_officer_nvgt_hashkey FROM tmp_link_customer_dept_acct_officer_nvgt);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_customer_dept_acct_officer_nvgt
    (link_customer_dept_acct_officer_nvgt_hashkey, customer_hashkey, dept_acct_officer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_customer_dept_acct_officer_nvgt_hashkey, customer_hashkey, dept_acct_officer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_customer_dept_acct_officer_nvgt_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_customer_dept_acct_officer_nvgt
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_customer_dept_acct_officer_nvgt_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_dept_acct_officer_nvgt
WHERE link_customer_dept_acct_officer_nvgt_hashkey IN (SELECT DISTINCT link_customer_dept_acct_officer_nvgt_hashkey FROM tmp_link_customer_dept_acct_officer_nvgt)
GROUP BY link_customer_dept_acct_officer_nvgt_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_customer_dept_acct_officer_nvgt;


-- =============================================================================
-- [T24] link_customer_dept_acct_officer_nvql — 2410 dups
-- Nguồn Duplicated: T24_CUSTOMER ngày 20240420
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_customer_dept_acct_officer_nvql
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_dept_acct_officer_nvql
WHERE link_customer_dept_acct_officer_nvql_hashkey IN (
    SELECT link_customer_dept_acct_officer_nvql_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_dept_acct_officer_nvql
    GROUP BY link_customer_dept_acct_officer_nvql_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_dept_acct_officer_nvql
WHERE link_customer_dept_acct_officer_nvql_hashkey IN (SELECT DISTINCT link_customer_dept_acct_officer_nvql_hashkey FROM tmp_link_customer_dept_acct_officer_nvql);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_customer_dept_acct_officer_nvql
    (link_customer_dept_acct_officer_nvql_hashkey, customer_hashkey, dept_acct_officer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_customer_dept_acct_officer_nvql_hashkey, customer_hashkey, dept_acct_officer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_customer_dept_acct_officer_nvql_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_customer_dept_acct_officer_nvql
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_customer_dept_acct_officer_nvql_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_dept_acct_officer_nvql
WHERE link_customer_dept_acct_officer_nvql_hashkey IN (SELECT DISTINCT link_customer_dept_acct_officer_nvql_hashkey FROM tmp_link_customer_dept_acct_officer_nvql)
GROUP BY link_customer_dept_acct_officer_nvql_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_customer_dept_acct_officer_nvql;


-- =============================================================================
-- [T24] link_customer_related_customer — 15 dups
-- Nguồn Duplicated: T24_CUSTOMER ngày 20240420
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_customer_related_customer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_related_customer
WHERE link_cust_relcust_hashkey IN (
    SELECT link_cust_relcust_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_related_customer
    GROUP BY link_cust_relcust_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_related_customer
WHERE link_cust_relcust_hashkey IN (SELECT DISTINCT link_cust_relcust_hashkey FROM tmp_link_customer_related_customer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_customer_related_customer
    (link_cust_relcust_hashkey, customer_hashkey, related_customer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_cust_relcust_hashkey, customer_hashkey, related_customer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_cust_relcust_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_customer_related_customer
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_cust_relcust_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_customer_related_customer
WHERE link_cust_relcust_hashkey IN (SELECT DISTINCT link_cust_relcust_hashkey FROM tmp_link_customer_related_customer)
GROUP BY link_cust_relcust_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_customer_related_customer;


-- =============================================================================
-- [T24] link_deposits_branch — 18 dups
-- Nguồn Duplicated: T24 az account
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_deposits_branch
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_branch
WHERE link_deposits_branch_hashkey IN (
    SELECT link_deposits_branch_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_branch
    GROUP BY link_deposits_branch_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_branch
WHERE link_deposits_branch_hashkey IN (SELECT DISTINCT link_deposits_branch_hashkey FROM tmp_link_deposits_branch);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_deposits_branch
    (link_deposits_branch_hashkey, deposit_hashkey, branch_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_deposits_branch_hashkey, deposit_hashkey, branch_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_deposits_branch_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_deposits_branch
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_deposits_branch_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_branch
WHERE link_deposits_branch_hashkey IN (SELECT DISTINCT link_deposits_branch_hashkey FROM tmp_link_deposits_branch)
GROUP BY link_deposits_branch_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_deposits_branch;


-- =============================================================================
-- [T24] link_deposits_customer — 18 dups
-- Nguồn Duplicated: T24 az account
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_deposits_customer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_customer
WHERE link_deposits_customer_hashkey IN (
    SELECT link_deposits_customer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_customer
    GROUP BY link_deposits_customer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_customer
WHERE link_deposits_customer_hashkey IN (SELECT DISTINCT link_deposits_customer_hashkey FROM tmp_link_deposits_customer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_deposits_customer
    (link_deposits_customer_hashkey, deposit_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_deposits_customer_hashkey, deposit_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_deposits_customer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_deposits_customer
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_deposits_customer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_customer
WHERE link_deposits_customer_hashkey IN (SELECT DISTINCT link_deposits_customer_hashkey FROM tmp_link_deposits_customer)
GROUP BY link_deposits_customer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_deposits_customer;


-- =============================================================================
-- [T24] link_deposits_nominated_account — 18 dups
-- Nguồn Duplicated: T24 az account
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_deposits_nominated_account
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_nominated_account
WHERE link_deposits_nominated_account_hashkey IN (
    SELECT link_deposits_nominated_account_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_nominated_account
    GROUP BY link_deposits_nominated_account_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_nominated_account
WHERE link_deposits_nominated_account_hashkey IN (SELECT DISTINCT link_deposits_nominated_account_hashkey FROM tmp_link_deposits_nominated_account);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_deposits_nominated_account
    (link_deposits_nominated_account_hashkey, deposit_hashkey, account_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_deposits_nominated_account_hashkey, deposit_hashkey, account_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_deposits_nominated_account_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_deposits_nominated_account
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_deposits_nominated_account_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_nominated_account
WHERE link_deposits_nominated_account_hashkey IN (SELECT DISTINCT link_deposits_nominated_account_hashkey FROM tmp_link_deposits_nominated_account)
GROUP BY link_deposits_nominated_account_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_deposits_nominated_account;


-- =============================================================================
-- [T24] link_deposits_repay_account — 18 dups
-- Nguồn Duplicated: T24 az account
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_deposits_repay_account
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_repay_account
WHERE link_deposits_repay_account_hashkey IN (
    SELECT link_deposits_repay_account_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_repay_account
    GROUP BY link_deposits_repay_account_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_repay_account
WHERE link_deposits_repay_account_hashkey IN (SELECT DISTINCT link_deposits_repay_account_hashkey FROM tmp_link_deposits_repay_account);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_deposits_repay_account
    (link_deposits_repay_account_hashkey, deposit_hashkey, account_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_deposits_repay_account_hashkey, deposit_hashkey, account_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_deposits_repay_account_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_deposits_repay_account
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_deposits_repay_account_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_deposits_repay_account
WHERE link_deposits_repay_account_hashkey IN (SELECT DISTINCT link_deposits_repay_account_hashkey FROM tmp_link_deposits_repay_account)
GROUP BY link_deposits_repay_account_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_deposits_repay_account;


-- =============================================================================
-- [WAY4] link_doc_fin_auth — 18 dups
-- Nguồn duplicate: lỗi nguồn do file nguồn thừa
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_doc_fin_auth
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_doc_fin_auth
WHERE link_doc_fin_auth_hashkey IN (
    SELECT link_doc_fin_auth_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_doc_fin_auth
    GROUP BY link_doc_fin_auth_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_doc_fin_auth
WHERE link_doc_fin_auth_hashkey IN (SELECT DISTINCT link_doc_fin_auth_hashkey FROM tmp_link_doc_fin_auth);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_doc_fin_auth
    (link_doc_fin_auth_hashkey, document_fin_hashkey, document_auth_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_doc_fin_auth_hashkey, document_fin_hashkey, document_auth_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_doc_fin_auth_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_doc_fin_auth
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_doc_fin_auth_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_doc_fin_auth
WHERE link_doc_fin_auth_hashkey IN (SELECT DISTINCT link_doc_fin_auth_hashkey FROM tmp_link_doc_fin_auth)
GROUP BY link_doc_fin_auth_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_doc_fin_auth;


-- =============================================================================
-- [WAY4] link_entry_acnt_contract — 9 dups
-- Nguồn duplicate: lỗi nguồn do file nguồn thừa
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_entry_acnt_contract
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_entry_acnt_contract
WHERE link_entry_acnt_contract_hashkey IN (
    SELECT link_entry_acnt_contract_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_entry_acnt_contract
    GROUP BY link_entry_acnt_contract_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_entry_acnt_contract
WHERE link_entry_acnt_contract_hashkey IN (SELECT DISTINCT link_entry_acnt_contract_hashkey FROM tmp_link_entry_acnt_contract);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_entry_acnt_contract
    (link_entry_acnt_contract_hashkey, entry_hashkey, acnt_contract_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_entry_acnt_contract_hashkey, entry_hashkey, acnt_contract_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_entry_acnt_contract_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_entry_acnt_contract
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_entry_acnt_contract_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_entry_acnt_contract
WHERE link_entry_acnt_contract_hashkey IN (SELECT DISTINCT link_entry_acnt_contract_hashkey FROM tmp_link_entry_acnt_contract)
GROUP BY link_entry_acnt_contract_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_entry_acnt_contract;


-- =============================================================================
-- [WAY4] link_entry_document — 1190 dups
-- Nguồn duplicate: lỗi nguồn do file nguồn thừa
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_entry_document
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_entry_document
WHERE link_entry_document_hashkey IN (
    SELECT link_entry_document_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_entry_document
    GROUP BY link_entry_document_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_entry_document
WHERE link_entry_document_hashkey IN (SELECT DISTINCT link_entry_document_hashkey FROM tmp_link_entry_document);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_entry_document
    (link_entry_document_hashkey, entry_hashkey, document_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_entry_document_hashkey, entry_hashkey, document_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_entry_document_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_entry_document
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_entry_document_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_entry_document
WHERE link_entry_document_hashkey IN (SELECT DISTINCT link_entry_document_hashkey FROM tmp_link_entry_document)
GROUP BY link_entry_document_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_entry_document;


-- =============================================================================
-- [WAY4] link_entry_m_transaction — 9/1190 dups
-- Nguồn duplicate: lỗi nguồn do file nguồn thừa
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_entry_m_transaction
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_entry_m_transaction
WHERE link_entry_m_transaction_hashkey IN (
    SELECT link_entry_m_transaction_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_entry_m_transaction
    GROUP BY link_entry_m_transaction_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_entry_m_transaction
WHERE link_entry_m_transaction_hashkey IN (SELECT DISTINCT link_entry_m_transaction_hashkey FROM tmp_link_entry_m_transaction);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_entry_m_transaction
    (link_entry_m_transaction_hashkey, entry_hashkey, m_transaction_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_entry_m_transaction_hashkey, entry_hashkey, m_transaction_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_entry_m_transaction_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_entry_m_transaction
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_entry_m_transaction_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_entry_m_transaction
WHERE link_entry_m_transaction_hashkey IN (SELECT DISTINCT link_entry_m_transaction_hashkey FROM tmp_link_entry_m_transaction)
GROUP BY link_entry_m_transaction_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_entry_m_transaction;


-- =============================================================================
-- [T24] link_funds_transfer_branch — 1079327 dups
-- Nguồn Duplicated: T24_funds_transfer dup 20260421
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_funds_transfer_branch
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_branch
WHERE link_funds_transfer_branch_hashkey IN (
    SELECT link_funds_transfer_branch_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_branch
    GROUP BY link_funds_transfer_branch_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_branch
WHERE link_funds_transfer_branch_hashkey IN (SELECT DISTINCT link_funds_transfer_branch_hashkey FROM tmp_link_funds_transfer_branch);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_branch
    (link_funds_transfer_branch_hashkey, funds_transfer_hashkey, branch_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_funds_transfer_branch_hashkey, funds_transfer_hashkey, branch_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_funds_transfer_branch_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_funds_transfer_branch
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_funds_transfer_branch_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_branch
WHERE link_funds_transfer_branch_hashkey IN (SELECT DISTINCT link_funds_transfer_branch_hashkey FROM tmp_link_funds_transfer_branch)
GROUP BY link_funds_transfer_branch_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_funds_transfer_branch;


-- =============================================================================
-- [T24] link_funds_transfer_clearing_citad — 3071 dups
-- Nguồn Duplicated: T24_funds_transfer dup 20260421
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_funds_transfer_clearing_citad
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_clearing_citad
WHERE link_funds_transfer_clearing_citad_hashkey IN (
    SELECT link_funds_transfer_clearing_citad_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_clearing_citad
    GROUP BY link_funds_transfer_clearing_citad_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_clearing_citad
WHERE link_funds_transfer_clearing_citad_hashkey IN (SELECT DISTINCT link_funds_transfer_clearing_citad_hashkey FROM tmp_link_funds_transfer_clearing_citad);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_clearing_citad
    (link_funds_transfer_clearing_citad_hashkey, funds_transfer_hashkey, clearing_citad_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_funds_transfer_clearing_citad_hashkey, funds_transfer_hashkey, clearing_citad_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_funds_transfer_clearing_citad_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_funds_transfer_clearing_citad
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_funds_transfer_clearing_citad_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_clearing_citad
WHERE link_funds_transfer_clearing_citad_hashkey IN (SELECT DISTINCT link_funds_transfer_clearing_citad_hashkey FROM tmp_link_funds_transfer_clearing_citad)
GROUP BY link_funds_transfer_clearing_citad_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_funds_transfer_clearing_citad;


-- =============================================================================
-- [T24] link_funds_transfer_credit_account — 359 dups
-- Nguồn Duplicated: T24_funds_transfer dup 20260421
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_funds_transfer_credit_account
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_credit_account
WHERE link_funds_transfer_credit_account_hashkey IN (
    SELECT link_funds_transfer_credit_account_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_credit_account
    GROUP BY link_funds_transfer_credit_account_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_credit_account
WHERE link_funds_transfer_credit_account_hashkey IN (SELECT DISTINCT link_funds_transfer_credit_account_hashkey FROM tmp_link_funds_transfer_credit_account);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_credit_account
    (link_funds_transfer_credit_account_hashkey, funds_transfer_hashkey, account_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_funds_transfer_credit_account_hashkey, funds_transfer_hashkey, account_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_funds_transfer_credit_account_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_funds_transfer_credit_account
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_funds_transfer_credit_account_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_credit_account
WHERE link_funds_transfer_credit_account_hashkey IN (SELECT DISTINCT link_funds_transfer_credit_account_hashkey FROM tmp_link_funds_transfer_credit_account)
GROUP BY link_funds_transfer_credit_account_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_funds_transfer_credit_account;


-- =============================================================================
-- [T24] link_funds_transfer_credit_customer — 664970 dups
-- Nguồn Duplicated: T24_funds_transfer dup 20260421
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_funds_transfer_credit_customer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_credit_customer
WHERE link_funds_transfer_credit_customer_hashkey IN (
    SELECT link_funds_transfer_credit_customer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_credit_customer
    GROUP BY link_funds_transfer_credit_customer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_credit_customer
WHERE link_funds_transfer_credit_customer_hashkey IN (SELECT DISTINCT link_funds_transfer_credit_customer_hashkey FROM tmp_link_funds_transfer_credit_customer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_credit_customer
    (link_funds_transfer_credit_customer_hashkey, funds_transfer_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_funds_transfer_credit_customer_hashkey, funds_transfer_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_funds_transfer_credit_customer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_funds_transfer_credit_customer
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_funds_transfer_credit_customer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_credit_customer
WHERE link_funds_transfer_credit_customer_hashkey IN (SELECT DISTINCT link_funds_transfer_credit_customer_hashkey FROM tmp_link_funds_transfer_credit_customer)
GROUP BY link_funds_transfer_credit_customer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_funds_transfer_credit_customer;


-- =============================================================================
-- [T24] link_funds_transfer_debit_account — 1079281 dups
-- Nguồn Duplicated: T24_funds_transfer dup 20260421
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_funds_transfer_debit_account
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_debit_account
WHERE link_funds_transfer_debit_account_hashkey IN (
    SELECT link_funds_transfer_debit_account_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_debit_account
    GROUP BY link_funds_transfer_debit_account_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_debit_account
WHERE link_funds_transfer_debit_account_hashkey IN (SELECT DISTINCT link_funds_transfer_debit_account_hashkey FROM tmp_link_funds_transfer_debit_account);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_debit_account
    (link_funds_transfer_debit_account_hashkey, funds_transfer_hashkey, account_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_funds_transfer_debit_account_hashkey, funds_transfer_hashkey, account_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_funds_transfer_debit_account_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_funds_transfer_debit_account
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_funds_transfer_debit_account_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_debit_account
WHERE link_funds_transfer_debit_account_hashkey IN (SELECT DISTINCT link_funds_transfer_debit_account_hashkey FROM tmp_link_funds_transfer_debit_account)
GROUP BY link_funds_transfer_debit_account_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_funds_transfer_debit_account;


-- =============================================================================
-- [T24] link_funds_transfer_debit_customer — 469884 dups
-- Nguồn Duplicated: T24_funds_transfer dup 20260421
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_funds_transfer_debit_customer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_debit_customer
WHERE link_funds_transfer_debit_customer_hashkey IN (
    SELECT link_funds_transfer_debit_customer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_debit_customer
    GROUP BY link_funds_transfer_debit_customer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_debit_customer
WHERE link_funds_transfer_debit_customer_hashkey IN (SELECT DISTINCT link_funds_transfer_debit_customer_hashkey FROM tmp_link_funds_transfer_debit_customer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_debit_customer
    (link_funds_transfer_debit_customer_hashkey, funds_transfer_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_funds_transfer_debit_customer_hashkey, funds_transfer_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_funds_transfer_debit_customer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_funds_transfer_debit_customer
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_funds_transfer_debit_customer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_funds_transfer_debit_customer
WHERE link_funds_transfer_debit_customer_hashkey IN (SELECT DISTINCT link_funds_transfer_debit_customer_hashkey FROM tmp_link_funds_transfer_debit_customer)
GROUP BY link_funds_transfer_debit_customer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_funds_transfer_debit_customer;


-- =============================================================================
-- [OMNI] link_onboarding_appflyer — 3 dups
-- Xuất hiện 3 bản ghi bị dup trong quá trình chạy, chưa tìm ra nguyên nhân cụ thể
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_onboarding_appflyer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_onboarding_appflyer
WHERE link_onboarding_appflyer_hashkey IN (
    SELECT link_onboarding_appflyer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_onboarding_appflyer
    GROUP BY link_onboarding_appflyer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_onboarding_appflyer
WHERE link_onboarding_appflyer_hashkey IN (SELECT DISTINCT link_onboarding_appflyer_hashkey FROM tmp_link_onboarding_appflyer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_onboarding_appflyer
    (link_onboarding_appflyer_hashkey, onboarding_hashkey, appflyer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_onboarding_appflyer_hashkey, onboarding_hashkey, appflyer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_onboarding_appflyer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_onboarding_appflyer
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_onboarding_appflyer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_onboarding_appflyer
WHERE link_onboarding_appflyer_hashkey IN (SELECT DISTINCT link_onboarding_appflyer_hashkey FROM tmp_link_onboarding_appflyer)
GROUP BY link_onboarding_appflyer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_onboarding_appflyer;


-- =============================================================================
-- [OMNI] link_onboarding_customer — 3 dups
-- Xuất hiện 3 bản ghi bị dup trong quá trình chạy, chưa tìm ra nguyên nhân cụ thể
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_onboarding_customer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_onboarding_customer
WHERE link_onboarding_customer_hashkey IN (
    SELECT link_onboarding_customer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_onboarding_customer
    GROUP BY link_onboarding_customer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_onboarding_customer
WHERE link_onboarding_customer_hashkey IN (SELECT DISTINCT link_onboarding_customer_hashkey FROM tmp_link_onboarding_customer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_onboarding_customer
    (link_onboarding_customer_hashkey, onboarding_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_onboarding_customer_hashkey, onboarding_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_onboarding_customer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_onboarding_customer
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_onboarding_customer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_onboarding_customer
WHERE link_onboarding_customer_hashkey IN (SELECT DISTINCT link_onboarding_customer_hashkey FROM tmp_link_onboarding_customer)
GROUP BY link_onboarding_customer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_onboarding_customer;


-- =============================================================================
-- [OMNI] link_payment_history_funds_transfer — 84 dups
-- Code sai filter data_date -> duplicate
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_payment_history_funds_transfer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_payment_history_funds_transfer
WHERE link_payment_history_funds_transfer_hashkey IN (
    SELECT link_payment_history_funds_transfer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_payment_history_funds_transfer
    GROUP BY link_payment_history_funds_transfer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_payment_history_funds_transfer
WHERE link_payment_history_funds_transfer_hashkey IN (SELECT DISTINCT link_payment_history_funds_transfer_hashkey FROM tmp_link_payment_history_funds_transfer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_payment_history_funds_transfer
    (link_payment_history_funds_transfer_hashkey, payment_history_hashkey, funds_transfer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_payment_history_funds_transfer_hashkey, payment_history_hashkey, funds_transfer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_payment_history_funds_transfer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_payment_history_funds_transfer
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_payment_history_funds_transfer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_payment_history_funds_transfer
WHERE link_payment_history_funds_transfer_hashkey IN (SELECT DISTINCT link_payment_history_funds_transfer_hashkey FROM tmp_link_payment_history_funds_transfer)
GROUP BY link_payment_history_funds_transfer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_payment_history_funds_transfer;


-- =============================================================================
-- [OMNI] link_payment_order_funds_transfer — 399983 dups
-- Code sai filter data_date -> duplicate
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_payment_order_funds_transfer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_payment_order_funds_transfer
WHERE link_payment_order_funds_transfer_hashkey IN (
    SELECT link_payment_order_funds_transfer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_payment_order_funds_transfer
    GROUP BY link_payment_order_funds_transfer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_payment_order_funds_transfer
WHERE link_payment_order_funds_transfer_hashkey IN (SELECT DISTINCT link_payment_order_funds_transfer_hashkey FROM tmp_link_payment_order_funds_transfer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_payment_order_funds_transfer
    (link_payment_order_funds_transfer_hashkey, payment_order_hashkey, funds_transfer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_payment_order_funds_transfer_hashkey, payment_order_hashkey, funds_transfer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_payment_order_funds_transfer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_payment_order_funds_transfer
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_payment_order_funds_transfer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_payment_order_funds_transfer
WHERE link_payment_order_funds_transfer_hashkey IN (SELECT DISTINCT link_payment_order_funds_transfer_hashkey FROM tmp_link_payment_order_funds_transfer)
GROUP BY link_payment_order_funds_transfer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_payment_order_funds_transfer;


-- =============================================================================
-- [OMNI] link_payment_order_user — 58 dups
-- Code sai filter data_date -> duplicate
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_payment_order_user
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_payment_order_user
WHERE link_payment_order_user_hashkey IN (
    SELECT link_payment_order_user_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_payment_order_user
    GROUP BY link_payment_order_user_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_payment_order_user
WHERE link_payment_order_user_hashkey IN (SELECT DISTINCT link_payment_order_user_hashkey FROM tmp_link_payment_order_user);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_payment_order_user
    (link_payment_order_user_hashkey, payment_order_hashkey, omni_user_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_payment_order_user_hashkey, payment_order_hashkey, omni_user_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_payment_order_user_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_payment_order_user
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_payment_order_user_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_payment_order_user
WHERE link_payment_order_user_hashkey IN (SELECT DISTINCT link_payment_order_user_hashkey FROM tmp_link_payment_order_user)
GROUP BY link_payment_order_user_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_payment_order_user;


-- =============================================================================
-- [T24] link_re_consol_spec_entry_branch — 613861/1 dups
-- Nguồn Duplicated: v_stg_t24_t24_line_mvmt_toanhang ngày 20260606 + T24_re_consol_spec_entry dup 20221010
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_re_consol_spec_entry_branch
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_branch
WHERE link_re_consol_spec_entry_branch_hashkey IN (
    SELECT link_re_consol_spec_entry_branch_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_branch
    GROUP BY link_re_consol_spec_entry_branch_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_branch
WHERE link_re_consol_spec_entry_branch_hashkey IN (SELECT DISTINCT link_re_consol_spec_entry_branch_hashkey FROM tmp_link_re_consol_spec_entry_branch);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_branch
    (link_re_consol_spec_entry_branch_hashkey, re_consol_spec_entry_hashkey, branch_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_re_consol_spec_entry_branch_hashkey, re_consol_spec_entry_hashkey, branch_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_re_consol_spec_entry_branch_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_re_consol_spec_entry_branch
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_re_consol_spec_entry_branch_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_branch
WHERE link_re_consol_spec_entry_branch_hashkey IN (SELECT DISTINCT link_re_consol_spec_entry_branch_hashkey FROM tmp_link_re_consol_spec_entry_branch)
GROUP BY link_re_consol_spec_entry_branch_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_re_consol_spec_entry_branch;


-- =============================================================================
-- [T24] link_re_consol_spec_entry_customer — 609513/1 dups
-- Nguồn Duplicated: v_stg_t24_t24_line_mvmt_toanhang ngày 20260606 + T24_re_consol_spec_entry dup 20221010
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_re_consol_spec_entry_customer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_customer
WHERE link_re_consol_spec_entry_customer_hashkey IN (
    SELECT link_re_consol_spec_entry_customer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_customer
    GROUP BY link_re_consol_spec_entry_customer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_customer
WHERE link_re_consol_spec_entry_customer_hashkey IN (SELECT DISTINCT link_re_consol_spec_entry_customer_hashkey FROM tmp_link_re_consol_spec_entry_customer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_customer
    (link_re_consol_spec_entry_customer_hashkey, re_consol_spec_entry_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_re_consol_spec_entry_customer_hashkey, re_consol_spec_entry_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_re_consol_spec_entry_customer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_re_consol_spec_entry_customer
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_re_consol_spec_entry_customer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_customer
WHERE link_re_consol_spec_entry_customer_hashkey IN (SELECT DISTINCT link_re_consol_spec_entry_customer_hashkey FROM tmp_link_re_consol_spec_entry_customer)
GROUP BY link_re_consol_spec_entry_customer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_re_consol_spec_entry_customer;


-- =============================================================================
-- [T24] link_re_consol_spec_entry_officer — 607615/1 dups
-- Nguồn Duplicated: v_stg_t24_t24_line_mvmt_toanhang ngày 20260606 + T24_re_consol_spec_entry dup 20221010
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_re_consol_spec_entry_officer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_officer
WHERE link_re_consol_spec_entry_officer_hashkey IN (
    SELECT link_re_consol_spec_entry_officer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_officer
    GROUP BY link_re_consol_spec_entry_officer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_officer
WHERE link_re_consol_spec_entry_officer_hashkey IN (SELECT DISTINCT link_re_consol_spec_entry_officer_hashkey FROM tmp_link_re_consol_spec_entry_officer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_officer
    (link_re_consol_spec_entry_officer_hashkey, re_consol_spec_entry_hashkey, dept_acct_officer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_re_consol_spec_entry_officer_hashkey, re_consol_spec_entry_hashkey, dept_acct_officer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_re_consol_spec_entry_officer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_re_consol_spec_entry_officer
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_re_consol_spec_entry_officer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_re_consol_spec_entry_officer
WHERE link_re_consol_spec_entry_officer_hashkey IN (SELECT DISTINCT link_re_consol_spec_entry_officer_hashkey FROM tmp_link_re_consol_spec_entry_officer)
GROUP BY link_re_consol_spec_entry_officer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_re_consol_spec_entry_officer;


-- =============================================================================
-- [T24] link_stmt_entry_branch — 2593119/15330 dups
-- Nguồn Duplicated: stg sai ngày 20260606 + t24_stmt_entry dup 20221010
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_stmt_entry_branch
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_branch
WHERE link_stmt_entry_branch_hashkey IN (
    SELECT link_stmt_entry_branch_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_branch
    GROUP BY link_stmt_entry_branch_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_branch
WHERE link_stmt_entry_branch_hashkey IN (SELECT DISTINCT link_stmt_entry_branch_hashkey FROM tmp_link_stmt_entry_branch);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_branch
    (link_stmt_entry_branch_hashkey, stmt_entry_hashkey, branch_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_stmt_entry_branch_hashkey, stmt_entry_hashkey, branch_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_stmt_entry_branch_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_stmt_entry_branch
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_stmt_entry_branch_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_branch
WHERE link_stmt_entry_branch_hashkey IN (SELECT DISTINCT link_stmt_entry_branch_hashkey FROM tmp_link_stmt_entry_branch)
GROUP BY link_stmt_entry_branch_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_stmt_entry_branch;


-- =============================================================================
-- [T24] link_stmt_entry_customer — 1139126/4212 dups
-- Nguồn Duplicated: stg sai ngày 20260606 + t24_stmt_entry dup 20221010
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_stmt_entry_customer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_customer
WHERE link_stmt_entry_customer_hashkey IN (
    SELECT link_stmt_entry_customer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_customer
    GROUP BY link_stmt_entry_customer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_customer
WHERE link_stmt_entry_customer_hashkey IN (SELECT DISTINCT link_stmt_entry_customer_hashkey FROM tmp_link_stmt_entry_customer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_customer
    (link_stmt_entry_customer_hashkey, stmt_entry_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_stmt_entry_customer_hashkey, stmt_entry_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_stmt_entry_customer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_stmt_entry_customer
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_stmt_entry_customer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_customer
WHERE link_stmt_entry_customer_hashkey IN (SELECT DISTINCT link_stmt_entry_customer_hashkey FROM tmp_link_stmt_entry_customer)
GROUP BY link_stmt_entry_customer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_stmt_entry_customer;


-- =============================================================================
-- [T24] link_stmt_entry_officer — 2593119/15329 dups
-- Nguồn Duplicated: stg sai ngày 20260606 + t24_stmt_entry dup 20221010
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_stmt_entry_officer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_officer
WHERE link_stmt_entry_officer_hashkey IN (
    SELECT link_stmt_entry_officer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_officer
    GROUP BY link_stmt_entry_officer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_officer
WHERE link_stmt_entry_officer_hashkey IN (SELECT DISTINCT link_stmt_entry_officer_hashkey FROM tmp_link_stmt_entry_officer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_officer
    (link_stmt_entry_officer_hashkey, stmt_entry_hashkey, dept_acct_officer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_stmt_entry_officer_hashkey, stmt_entry_hashkey, dept_acct_officer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_stmt_entry_officer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_stmt_entry_officer
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_stmt_entry_officer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_stmt_entry_officer
WHERE link_stmt_entry_officer_hashkey IN (SELECT DISTINCT link_stmt_entry_officer_hashkey FROM tmp_link_stmt_entry_officer)
GROUP BY link_stmt_entry_officer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_stmt_entry_officer;


-- =============================================================================
-- [T24] link_teller_account1 — 1 dup
-- Nguồn Key viết hoa/thường -> gen ra cùng 1 hashkey tại hub
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_teller_account1
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_account1
WHERE link_teller_account1_hashkey IN (
    SELECT link_teller_account1_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_account1
    GROUP BY link_teller_account1_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_account1
WHERE link_teller_account1_hashkey IN (SELECT DISTINCT link_teller_account1_hashkey FROM tmp_link_teller_account1);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_teller_account1
    (link_teller_account1_hashkey, teller_hashkey, account_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_teller_account1_hashkey, teller_hashkey, account_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_teller_account1_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_teller_account1
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_teller_account1_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_account1
WHERE link_teller_account1_hashkey IN (SELECT DISTINCT link_teller_account1_hashkey FROM tmp_link_teller_account1)
GROUP BY link_teller_account1_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_teller_account1;


-- =============================================================================
-- [T24] link_teller_account2 — 1 dup
-- Nguồn Key viết hoa/thường -> gen ra cùng 1 hashkey tại hub
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_teller_account2
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_account2
WHERE link_teller_account2_hashkey IN (
    SELECT link_teller_account2_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_account2
    GROUP BY link_teller_account2_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_account2
WHERE link_teller_account2_hashkey IN (SELECT DISTINCT link_teller_account2_hashkey FROM tmp_link_teller_account2);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_teller_account2
    (link_teller_account2_hashkey, teller_hashkey, account_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_teller_account2_hashkey, teller_hashkey, account_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_teller_account2_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_teller_account2
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_teller_account2_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_account2
WHERE link_teller_account2_hashkey IN (SELECT DISTINCT link_teller_account2_hashkey FROM tmp_link_teller_account2)
GROUP BY link_teller_account2_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_teller_account2;


-- =============================================================================
-- [T24] link_teller_branch — 1 dup
-- Nguồn Key viết hoa/thường -> gen ra cùng 1 hashkey tại hub
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_teller_branch
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_branch
WHERE link_teller_branch_hashkey IN (
    SELECT link_teller_branch_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_branch
    GROUP BY link_teller_branch_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_branch
WHERE link_teller_branch_hashkey IN (SELECT DISTINCT link_teller_branch_hashkey FROM tmp_link_teller_branch);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_teller_branch
    (link_teller_branch_hashkey, teller_hashkey, branch_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_teller_branch_hashkey, teller_hashkey, branch_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_teller_branch_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_teller_branch
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_teller_branch_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_branch
WHERE link_teller_branch_hashkey IN (SELECT DISTINCT link_teller_branch_hashkey FROM tmp_link_teller_branch)
GROUP BY link_teller_branch_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_teller_branch;


-- =============================================================================
-- [T24] link_teller_customer1 — 1 dup
-- Nguồn Key viết hoa/thường -> gen ra cùng 1 hashkey tại hub
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_teller_customer1
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_customer1
WHERE link_teller_customer1_hashkey IN (
    SELECT link_teller_customer1_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_customer1
    GROUP BY link_teller_customer1_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_customer1
WHERE link_teller_customer1_hashkey IN (SELECT DISTINCT link_teller_customer1_hashkey FROM tmp_link_teller_customer1);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_teller_customer1
    (link_teller_customer1_hashkey, teller_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_teller_customer1_hashkey, teller_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_teller_customer1_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_teller_customer1
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_teller_customer1_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_customer1
WHERE link_teller_customer1_hashkey IN (SELECT DISTINCT link_teller_customer1_hashkey FROM tmp_link_teller_customer1)
GROUP BY link_teller_customer1_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_teller_customer1;


-- =============================================================================
-- [T24] link_teller_customer2 — 1 dup
-- Nguồn Key viết hoa/thường -> gen ra cùng 1 hashkey tại hub
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_teller_customer2
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_customer2
WHERE link_teller_customer2_hashkey IN (
    SELECT link_teller_customer2_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_customer2
    GROUP BY link_teller_customer2_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_customer2
WHERE link_teller_customer2_hashkey IN (SELECT DISTINCT link_teller_customer2_hashkey FROM tmp_link_teller_customer2);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_teller_customer2
    (link_teller_customer2_hashkey, teller_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_teller_customer2_hashkey, teller_hashkey, customer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_teller_customer2_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_teller_customer2
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_teller_customer2_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_teller_customer2
WHERE link_teller_customer2_hashkey IN (SELECT DISTINCT link_teller_customer2_hashkey FROM tmp_link_teller_customer2)
GROUP BY link_teller_customer2_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_teller_customer2;


-- =============================================================================
-- [OMNI] link_transfer_bill_funds_transfer — 3170 dups
-- Code sai filter data_date -> duplicate
-- =============================================================================
CREATE OR REPLACE TEMPORARY TABLE tmp_link_transfer_bill_funds_transfer
AS SELECT * FROM ocb_datavault_prod_cleaned.raw_vault.link_transfer_bill_funds_transfer
WHERE link_transfer_bill_funds_transfer_hashkey IN (
    SELECT link_transfer_bill_funds_transfer_hashkey FROM ocb_datavault_prod_cleaned.raw_vault.link_transfer_bill_funds_transfer
    GROUP BY link_transfer_bill_funds_transfer_hashkey HAVING COUNT(*) > 1
);

DELETE FROM ocb_datavault_prod_cleaned.raw_vault.link_transfer_bill_funds_transfer
WHERE link_transfer_bill_funds_transfer_hashkey IN (SELECT DISTINCT link_transfer_bill_funds_transfer_hashkey FROM tmp_link_transfer_bill_funds_transfer);

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.link_transfer_bill_funds_transfer
    (link_transfer_bill_funds_transfer_hashkey, transfer_bill_hashkey, funds_transfer_hashkey, source_event_date, record_source, load_timestamp)
SELECT link_transfer_bill_funds_transfer_hashkey, transfer_bill_hashkey, funds_transfer_hashkey, source_event_date, record_source, load_timestamp
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY link_transfer_bill_funds_transfer_hashkey ORDER BY source_event_date ASC, load_timestamp ASC) AS _rn
    FROM tmp_link_transfer_bill_funds_transfer
) WHERE _rn = 1;

-- Verify: mong đợi 0 rows
SELECT link_transfer_bill_funds_transfer_hashkey, COUNT(*) cnt FROM ocb_datavault_prod_cleaned.raw_vault.link_transfer_bill_funds_transfer
WHERE link_transfer_bill_funds_transfer_hashkey IN (SELECT DISTINCT link_transfer_bill_funds_transfer_hashkey FROM tmp_link_transfer_bill_funds_transfer)
GROUP BY link_transfer_bill_funds_transfer_hashkey HAVING cnt > 1;

DROP TEMPORARY TABLE IF EXISTS tmp_link_transfer_bill_funds_transfer;
