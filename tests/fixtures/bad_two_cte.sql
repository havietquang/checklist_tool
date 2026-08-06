-- FIXTURE co tinh SAI: cung mot bang raw_vault duoc doc o HAI CTE khac nhau
-- -> hai snapshot doc lap trong cung mot script, de lech thoi diem du lieu.
--   2.12 FAIL
CREATE OR REPLACE TABLE ocb_datavault_dev_curated.tckh.BAD_TWO_CTE AS
WITH a AS (
    SELECT customer_hashkey,
           max_by(cst_nm, source_event_date) AS CST_NM
    FROM   ocb_datavault_dev_cleaned.raw_vault.sat_customer_profile
    WHERE  source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP  BY customer_hashkey
),
b AS (
    SELECT customer_hashkey,
           max_by(cst_typ, source_event_date) AS CST_TYP
    FROM   ocb_datavault_dev_cleaned.raw_vault.sat_customer_profile
    WHERE  source_event_date <= TO_DATE(:DATADT, 'yyyyMMdd')
    GROUP  BY customer_hashkey
)
SELECT a.customer_hashkey AS CST_ID,
       a.CST_NM           AS CST_NM,
       b.CST_TYP          AS CST_TYP
FROM   a
LEFT   JOIN b ON b.customer_hashkey = a.customer_hashkey;
