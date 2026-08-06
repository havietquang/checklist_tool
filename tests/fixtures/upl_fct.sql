-- FIXTURE DUNG: view doc bang UPLOAD/THU CONG, nguon da khai o cot NOTE cua JOIN SCHEMA
-- ('TABLE upload thu cong (khong qua ETL/Silver)' trong UPL_FCT_Silver_to_Gold.xlsx).
--   X.9 PASS - bang upload la nguon hop le KHI da khai bao
--   X.8 PASS - ten bang trong SQL khop JOIN SCHEMA
CREATE OR REPLACE VIEW ocb_datavault_dev_curated.tckh.upl_fct AS
SELECT u.CDR_DT_ID AS CDR_DT_ID,
       u.RATE_VAL  AS RATE_VAL
FROM   ocb_datavault_dev_curated.tckh.tb_manual_upl u
WHERE  u.CDR_DT_ID = CAST(:DATADT AS INT);
