-- Object   : V_USD_RATE
-- Workbook : 037. OCB_GOLD_TCKH_V_USD_RATE_QUANG.xlsx
-- Sheet    : Script SQL
-- PIC      : QUANG
-- Nguon    : tai lieu mapping (input/mapping), KHONG phai code trong src/

USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

CREATE OR REPLACE VIEW v_usd_rate AS
SELECT
    DATA_DATE                                                                  AS CDR_DT_ID,
    ID                                                                         AS CURCODE,
    CAST(element_at(split(T_MID_REVAL_RATE, '::'),
                    CAST(array_position(split(T_CURRENCY_MARKET, '::'), '1') AS INT)) AS DECIMAL(20,4)) AS MIDRATE
FROM IDENTIFIER(:cleaned || '.raw_vault.ref_currency')
WHERE ID = 'USD'
AND array_position(split(T_CURRENCY_MARKET, '::'), '1') > 0   -- chi lay dong co market = 1
ORDER BY DATA_DATE;