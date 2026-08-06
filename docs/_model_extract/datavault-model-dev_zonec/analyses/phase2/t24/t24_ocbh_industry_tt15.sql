-- Source: .t24.t24_ocbh_industry_tt15
-- Target: ref_t24_ocbh_industry_tt15
-- Range: 20250101 -> 20250131

DROP TEMPORARY TABLE IF EXISTS tmp_t24_ocbh_industry_tt15; CREATE TEMPORARY TABLE tmp_t24_ocbh_industry_tt15 AS
SELECT
    id,
    t_industry_tt15_l1,
    t_industry_tt15_l2,
    t_industry_tt15_l3,
    t_industry_name,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_ocbh_industry_tt15')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [ref_t24_ocbh_industry_tt15] Insert new/updated records (ANTI JOIN on id + source_event_date to capture daily changes)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_ocbh_industry_tt15')
(id, t_industry_tt15_l1, t_industry_tt15_l2, t_industry_tt15_l3, t_industry_name, source_event_date, record_source, load_timestamp)
WITH deduped AS (SELECT * FROM tmp_t24_ocbh_industry_tt15 QUALIFY ROW_NUMBER() OVER (PARTITION BY id, data_date ORDER BY data_date) = 1)
SELECT d.id, d.t_industry_tt15_l1, d.t_industry_tt15_l2, d.t_industry_tt15_l3, d.t_industry_name, d.source_event_date, 't24__t24_ocbh_industry_tt15', current_timestamp()
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_ocbh_industry_tt15') t
    ON t.id = d.id AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_ocbh_industry_tt15;
