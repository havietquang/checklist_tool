-- Source: .t24.t24_denom_exchange
-- Target: ref_t24_denom_exchange
-- Range: 20250101 -> 20250131

DROP TEMPORARY TABLE IF EXISTS tmp_t24_denom_exchange; CREATE TEMPORARY TABLE tmp_t24_denom_exchange AS
SELECT
    ID,
    data_date,
    t_denomination,
    t_denom_buy_rate,
    t_denom_sell_rate,
    t_denom_revl_rate,
    t_denom_rate_sprd,
    t_curr_no,
    t_inputter,
    t_date_time,
    t_authoriser,
    to_date(data_date, 'yyyyMMdd') AS source_event_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_denom_exchange')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND ID IS NOT NULL;

-- [ref_t24_denom_exchange] Insert new/updated records (ANTI JOIN on ID + source_event_date to capture daily changes)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_denom_exchange')
(ID, data_date, t_denomination, t_denom_buy_rate, t_denom_sell_rate, t_denom_revl_rate, t_denom_rate_sprd, t_curr_no, t_inputter, t_date_time, t_authoriser, source_event_date, record_source, load_timestamp)
WITH deduped AS (SELECT * FROM tmp_t24_denom_exchange QUALIFY ROW_NUMBER() OVER (PARTITION BY ID, data_date ORDER BY data_date) = 1)
SELECT d.ID, d.data_date, d.t_denomination, d.t_denom_buy_rate, d.t_denom_sell_rate, d.t_denom_revl_rate, d.t_denom_rate_sprd, d.t_curr_no, d.t_inputter, d.t_date_time, d.t_authoriser, d.source_event_date, 't24__t24_denom_exchange', current_timestamp()
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_denom_exchange') t
    ON t.ID = d.ID AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_denom_exchange;
