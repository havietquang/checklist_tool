-- FIXTURE DUNG: file chi co DDL, khong doc bang nguon nao (bang nap data tay tu CSV).
-- Ten file = ten object -> tieu chi 1.4 khong bao lech ten.
-- Ten bang trong DDL viet TRAN, ctx.target duoc bo sung catalog.schema tu USE CATALOG/SCHEMA
-- -> khong duoc tinh chinh no thanh bang NGUON.
--   X.9 N-A  - script khong doc bang nguon nao
--   1.1 doc duoc 4 cot tu dinh nghia DDL (khong co cau SELECT)
USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

CREATE TABLE IF NOT EXISTS tb_manual_dtl (
    CDR_DT_ID   int,
    ACCOUNT_ID  string,
    CCY         string,
    BAL_AMT     decimal(24,4)
)
USING DELTA
