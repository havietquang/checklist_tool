USE CATALOG IDENTIFIER(:curated);
USE SCHEMA tckh;

CREATE TABLE IF NOT EXISTS tb_cdkt_daily_dtl (
    Ccy             string,
    Account_ID      string,
    SubBranch_ID    string,
    NAME            string,
    DDN             decimal(24,4),
    DDC             decimal(24,4),
    DSN             decimal(24,4),
    DSC             decimal(24,4),
    DCN             decimal(24,4),
    DCC             decimal(24,4),
    `Table Names`   string,
    `File Paths`    string,
    DATA_DAY        string,
    DATA_MONTH      string,
    DATA_YEAR       string,
    CDR_DT_ID       int
)
USING DELTA
