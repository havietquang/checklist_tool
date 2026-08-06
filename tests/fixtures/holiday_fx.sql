-- FIXTURE DUNG: self-join mot bang trong CUNG mot khoi SELECT, filter rieng dat trong ON.
--   2.12 PASS - hai alias D/W doc cung mot snapshot, khong lech thoi diem du lieu
--   3.3  PASS - W.bsn_day_f = 1 BUOC PHAI nam trong ON (chuyen ra WHERE thanh INNER JOIN)
CREATE OR REPLACE TABLE ocb_datavault_dev_curated.tckh.HOLIDAY_FX AS
SELECT D.msr_prd_id       AS HOLIDAY_DT,
       MAX(W.msr_prd_id)  AS DATA_DT
FROM ocb_datavault_dev_cleaned.business_vault.calendar D
LEFT JOIN ocb_datavault_dev_cleaned.business_vault.calendar W
       ON  D.msr_prd_id > W.msr_prd_id
       AND W.bsn_day_f = 1
WHERE D.bsn_day_f = 0
GROUP BY D.msr_prd_id;
