-- Source: .t24.t24_acct_group_condition
-- Target: ref_t24_acct_group_condition
-- Range: 20250101 -> 20250131

DROP TEMPORARY TABLE IF EXISTS tmp_t24_acct_group_condition; CREATE TEMPORARY TABLE tmp_t24_acct_group_condition AS
SELECT
    ID,
    t_minimum_bal,
    t_curr_no,
    inputter,
    t_date_time,
    t_authoriser,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_acct_group_condition')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND ID IS NOT NULL;

-- [ref_t24_acct_group_condition] Insert new/updated records (ANTI JOIN on ID + source_event_date to capture daily changes)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_acct_group_condition')
(ID, t_minimum_bal, t_curr_no, inputter, t_date_time, t_authoriser, source_event_date, record_source, load_timestamp)
WITH deduped AS (SELECT * FROM tmp_t24_acct_group_condition QUALIFY ROW_NUMBER() OVER (PARTITION BY ID, data_date ORDER BY data_date) = 1)
SELECT d.ID, d.t_minimum_bal, d.t_curr_no, d.inputter, d.t_date_time, d.t_authoriser, d.source_event_date, 't24__t24_acct_group_condition', current_timestamp()
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_acct_group_condition') t
    ON t.ID = d.ID AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_acct_group_condition;
