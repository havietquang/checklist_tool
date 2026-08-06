-- FIXTURE co tinh SAI: ten object trong cau CREATE (tb_typo_dtl) KHAC ten file
-- (name_mismatch.sql). Loi kieu nay tung lot vi attach_mapping co fallback ghep
-- workbook theo TEN FILE, nen object viet sai ten ben trong van duoc cham binh thuong.
--   1.4 FAIL
CREATE TABLE IF NOT EXISTS ocb_datavault_dev_curated.tckh.tb_typo_dtl (
    CDR_DT_ID   int,
    ACCOUNT_ID  string,
    BAL_AMT     decimal(24,4)
)
USING DELTA
