-- Source: .t24.t24_group_capitalisation
-- Target: ref_t24_group_capitalisation
-- Range: 20250101 -> 20250131

DROP TEMPORARY TABLE IF EXISTS tmp_t24_group_capitalisation; CREATE TEMPORARY TABLE tmp_t24_group_capitalisation AS
SELECT
    ID,
    data_date,
    t_dr_cap_frequency,
    t_cr_cap_frequency,
    t_settle_acct_close,
    t_start_of_day_cap,
    to_date(data_date, 'yyyyMMdd') AS source_event_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_group_capitalisation')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND ID IS NOT NULL;

-- [ref_t24_group_capitalisation] Insert new/updated records (ANTI JOIN on ID + source_event_date to capture daily changes)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_group_capitalisation')
(ID, data_date, t_dr_cap_frequency, t_cr_cap_frequency, t_settle_acct_close, t_start_of_day_cap, source_event_date, record_source, load_timestamp)
WITH deduped AS (SELECT * FROM tmp_t24_group_capitalisation QUALIFY ROW_NUMBER() OVER (PARTITION BY ID, data_date ORDER BY data_date) = 1)
SELECT d.ID, d.data_date, d.t_dr_cap_frequency, d.t_cr_cap_frequency, d.t_settle_acct_close, d.t_start_of_day_cap, d.source_event_date, 't24__t24_group_capitalisation', current_timestamp()
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_group_capitalisation') t
    ON t.ID = d.ID AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_group_capitalisation;
