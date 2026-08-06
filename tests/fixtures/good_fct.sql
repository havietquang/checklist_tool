-- FIXTURE dung pattern chuan Technical_Document III.4.2:
--   sts_hub anti-join -> hub active; satellite MAX_BY + cutoff <=; link rut ve current
DELETE FROM ocb_datavault_dev_curated.tckh.GOOD_FCT
WHERE CDR_DT_ID = CAST(:DATADT AS INT);

INSERT INTO ocb_datavault_dev_curated.tckh.GOOD_FCT (CST_ID, BAL_AMT_LCY, CDR_DT_ID)
WITH customer_sts_del AS (
    SELECT customer_hashkey
    FROM   ocb_datavault_dev_cleaned.raw_vault.sts_hub_customer
    WHERE  source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY customer_hashkey
    HAVING max_by(cdc_status, source_event_date) = 'D'
),
customer_active AS (
    SELECT h.customer_hashkey, h.business_key
    FROM      ocb_datavault_dev_cleaned.raw_vault.hub_customer h
    LEFT JOIN customer_sts_del d ON d.customer_hashkey = h.customer_hashkey
    WHERE h.source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
      AND d.customer_hashkey IS NULL
),
customer_sat AS (
    SELECT customer_hashkey,
           max_by(cust_group, source_event_date) AS cust_group
    FROM   ocb_datavault_dev_cleaned.raw_vault.sat_customer_classification
    WHERE  source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY customer_hashkey
),
account_customer_cur AS (
    -- link 1:N: driving key = account_hashkey (mot account thuoc mot CIF)
    SELECT account_hashkey,
           max_by(customer_hashkey, source_event_date) AS customer_hashkey
    FROM   ocb_datavault_dev_cleaned.raw_vault.link_account_customer
    WHERE  source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY account_hashkey
),
bal AS (
    -- sat_account_balance thuoc 49 bang transaction -> loc = :DATADT
    SELECT account_hashkey,
           max_by(balance, source_event_date) AS balance
    FROM   ocb_datavault_dev_cleaned.raw_vault.sat_account_balance
    WHERE  source_event_date = TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP BY account_hashkey
)
SELECT a.customer_hashkey          AS CST_ID,
       COALESCE(SUM(b.balance), 0) AS BAL_AMT_LCY,
       CAST(:DATADT AS INT)        AS CDR_DT_ID
FROM      customer_active a
LEFT JOIN customer_sat        s  ON s.customer_hashkey = a.customer_hashkey
LEFT JOIN account_customer_cur lc ON lc.customer_hashkey = a.customer_hashkey
LEFT JOIN bal                  b  ON b.account_hashkey = lc.account_hashkey
GROUP BY a.customer_hashkey;
