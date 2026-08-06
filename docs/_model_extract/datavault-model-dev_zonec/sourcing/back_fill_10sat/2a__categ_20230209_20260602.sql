-- Source: t24_categ_entry | Full range 20230209 → 20260602
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20230209';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260602';

DROP TEMPORARY TABLE IF EXISTS tmp_categ; CREATE TEMPORARY TABLE tmp_categ AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS categ_entry_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_inputter        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_authoriser      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_time       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pc_period_end   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_reversal_marker AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_booking_date    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_accounting_date AS string))), ''), 256) AS hd_audit,
    sha2(COALESCE(UPPER(TRIM(CAST(t_currency        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amount_fcy      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amount_lcy      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_value_date      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_narrative       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_trans_reference AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_their_reference AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_our_reference   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_stmt_no         AS string))), ''), 256) AS hd_information,
    sha2(COALESCE(UPPER(TRIM(CAST(t_product_category AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pl_category      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_crf_type         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_system_id        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_transaction_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_consol_key       AS string))), ''), 256) AS hd_classification,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    t_inputter, t_authoriser, t_date_time, t_pc_period_end, t_reversal_marker, t_booking_date, t_accounting_date,
    t_currency, t_amount_fcy, t_amount_lcy, t_value_date, t_narrative, t_trans_reference, t_their_reference, t_our_reference, t_stmt_no,
    t_product_category, t_pl_category, t_crf_type, t_system_id, t_transaction_code, t_consol_key
FROM ocb_datavault_prod_sourcing.t24.t24_categ_entry
WHERE data_date BETWEEN start_date AND end_date AND id IS NOT NULL;

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_audit
(categ_entry_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_inputter, t_authoriser, t_date_time, t_pc_period_end, t_reversal_marker, t_booking_date, t_accounting_date)
WITH deduped AS (SELECT * FROM tmp_categ QUALIFY ROW_NUMBER() OVER (PARTITION BY categ_entry_hashkey, hd_audit ORDER BY data_date) = 1)
SELECT d.categ_entry_hashkey, d.hd_audit, d.source_event_date, current_timestamp(), 't24__t24_categ_entry',
       d.t_inputter, d.t_authoriser, d.t_date_time, d.t_pc_period_end, d.t_reversal_marker, d.t_booking_date, d.t_accounting_date
FROM deduped d LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_audit t
    ON t.categ_entry_hashkey = d.categ_entry_hashkey AND t.hashdiff = d.hd_audit;

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_information
(categ_entry_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_currency, t_amount_fcy, t_amount_lcy, t_value_date, t_narrative, t_trans_reference, t_their_reference, t_our_reference, t_stmt_no)
WITH deduped AS (SELECT * FROM tmp_categ QUALIFY ROW_NUMBER() OVER (PARTITION BY categ_entry_hashkey, hd_information ORDER BY data_date) = 1)
SELECT d.categ_entry_hashkey, d.hd_information, d.source_event_date, current_timestamp(), 't24__t24_categ_entry',
       d.t_currency, d.t_amount_fcy, d.t_amount_lcy, d.t_value_date, d.t_narrative,
       d.t_trans_reference, d.t_their_reference, d.t_our_reference, d.t_stmt_no
FROM deduped d LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_information t
    ON t.categ_entry_hashkey = d.categ_entry_hashkey AND t.hashdiff = d.hd_information;

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_classification
(categ_entry_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_product_category, t_pl_category, t_crf_type, t_system_id, t_transaction_code, t_consol_key)
WITH deduped AS (SELECT * FROM tmp_categ QUALIFY ROW_NUMBER() OVER (PARTITION BY categ_entry_hashkey, hd_classification ORDER BY data_date) = 1)
SELECT d.categ_entry_hashkey, d.hd_classification, d.source_event_date, current_timestamp(), 't24__t24_categ_entry',
       d.t_product_category, d.t_pl_category, d.t_crf_type, d.t_system_id, d.t_transaction_code, d.t_consol_key
FROM deduped d LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_categ_entry_classification t
    ON t.categ_entry_hashkey = d.categ_entry_hashkey AND t.hashdiff = d.hd_classification;

DROP TEMPORARY TABLE IF EXISTS tmp_categ;
