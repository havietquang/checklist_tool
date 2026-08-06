-- Source: .t24.t24_lc_enrichment
-- Target: ref_t24_lc_enrichment
-- Range: 20250101 -> 20250131

DROP TEMPORARY TABLE IF EXISTS tmp_t24_lc_enrichment; CREATE TEMPORARY TABLE tmp_t24_lc_enrichment AS
SELECT
    ID,
    t_operation,
    t_revocable,
    t_ucp_ind,
    t_part_ship,
    t_transship,
    t_reimburse,
    t_charges_from,
    t_party_chrgd,
    t_chrg_status,
    t_drawing_type,
    t_pay_method,
    t_coll_reply,
    t_chrg_period,
    t_imp_exp,
    t_pay_type,
    t_inco_terms,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_lc_enrichment')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND ID IS NOT NULL;

-- [ref_t24_lc_enrichment] Insert new/updated records (ANTI JOIN on ID + source_event_date to capture daily changes)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_lc_enrichment')
(ID, t_operation, t_revocable, t_ucp_ind, t_part_ship, t_transship, t_reimburse, t_charges_from,
 t_party_chrgd, t_chrg_status, t_drawing_type, t_pay_method, t_coll_reply, t_chrg_period,
 t_imp_exp, t_pay_type, t_inco_terms, source_event_date, record_source, load_timestamp)
WITH deduped AS (SELECT * FROM tmp_t24_lc_enrichment QUALIFY ROW_NUMBER() OVER (PARTITION BY ID, data_date ORDER BY data_date) = 1)
SELECT d.ID, d.t_operation, d.t_revocable, d.t_ucp_ind, d.t_part_ship, d.t_transship, d.t_reimburse, d.t_charges_from,
       d.t_party_chrgd, d.t_chrg_status, d.t_drawing_type, d.t_pay_method, d.t_coll_reply, d.t_chrg_period,
       d.t_imp_exp, d.t_pay_type, d.t_inco_terms, d.source_event_date, 't24__t24_lc_enrichment', current_timestamp()
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.ref_t24_lc_enrichment') t
    ON t.ID = d.ID AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_lc_enrichment;
