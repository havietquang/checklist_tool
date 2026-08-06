-- FIXTURE: doc mot bang Gold KHONG nam trong luot chay (khong object nao trong batch tao ra no).
-- May khong co du lieu de biet bang do co dev tu Silver hay khong -> KHONG duoc bao Fail.
--   X.9 MANUAL (ghi Pass + to vang, note noi ro thieu object nao)
CREATE OR REPLACE VIEW ocb_datavault_dev_curated.tckh.v_unknown_src AS
SELECT s.CDR_DT_ID AS CDR_DT_ID,
       s.BAL_AMT   AS BAL_AMT
FROM   ocb_datavault_dev_curated.tckh.tb_khong_co_trong_batch s
WHERE  s.CDR_DT_ID = CAST(:DATADT AS INT);
