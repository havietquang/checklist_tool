-- FIXTURE co tinh SAI so voi Technical_Document III.4.2:
--   2.1 hub khong loc qua sts_hub + loc cdc_status sai tang trong satellite
--   2.3 rn=1 long trong LEFT JOIN ON | 2.4 thieu cutoff | 3.1 SELECT * | 3.5 ROW_NUMBER
--   X.1 link chua rut current | X.6 INNER JOIN satellite | X.2 tron env | X.3 X.4
INSERT INTO ocb_datavault_dev_curated.tckh.BAD_FCT
WITH s AS (
    SELECT *
    FROM ocb_datavault_dev_cleaned.raw_vault.sat_customer_classification
    WHERE cdc_status <> 'D'
)
SELECT h.customer_hashkey AS CST_ID,
       SUM(a.balance)     AS BAL_AMT_LCY
FROM ocb_datavault_pilotcloud_cleaned.raw_vault.hub_customer h
JOIN ocb_datavault_dev_cleaned.raw_vault.sat_customer_kyc k
       ON k.customer_hashkey = h.customer_hashkey
LEFT JOIN ocb_datavault_dev_cleaned.raw_vault.link_account_customer lc
       ON lc.customer_hashkey = h.customer_hashkey
LEFT JOIN (SELECT account_hashkey, balance,
                  ROW_NUMBER() OVER (PARTITION BY account_hashkey ORDER BY source_event_date DESC) AS rn
           FROM ocb_datavault_dev_cleaned.raw_vault.sat_deposits_rate) a
       ON a.account_hashkey = lc.account_hashkey AND a.rn = 1
LEFT JOIN s ON s.customer_hashkey = h.customer_hashkey
GROUP BY h.customer_hashkey;
