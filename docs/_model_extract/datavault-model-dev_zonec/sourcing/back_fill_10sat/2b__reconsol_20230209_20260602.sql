-- Source: t24_re_consol_spec_entry | Full range 20230209 → 20260602
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20230209';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260602';

DROP TEMPORARY TABLE IF EXISTS tmp_reconsol; CREATE TEMPORARY TABLE tmp_reconsol AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS re_consol_spec_entry_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_reversal_marker AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_record_status   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_curr_no         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_inputter        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_time       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_authoriser      AS string))), ''), 256) AS hd_audit,
    sha2(COALESCE(UPPER(TRIM(CAST(t_amount_lcy      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_narrative       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_value_date      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amount_fcy      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_exchange_rate   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_our_reference   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_local_ref       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_trans_reference AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_booking_date    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_stmt_no         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_currency        AS string))), ''), 256) AS hd_information,
    sha2(COALESCE(UPPER(TRIM(CAST(t_consol_key_type  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pl_category      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_product_category AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_system_id        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_department_code  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_transaction_code AS string))), ''), 256) AS hd_classification,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    t_reversal_marker, t_record_status, t_curr_no, t_inputter, t_date_time, t_authoriser,
    t_amount_lcy, t_narrative, t_value_date, t_amount_fcy, t_exchange_rate,
    t_our_reference, t_local_ref, t_trans_reference, t_booking_date, t_stmt_no, t_currency,
    t_consol_key_type, t_pl_category, t_product_category, t_system_id, t_department_code, t_transaction_code
FROM ocb_datavault_prod_sourcing.t24.t24_re_consol_spec_entry
WHERE data_date BETWEEN start_date AND end_date AND id IS NOT NULL;

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_audit
(re_consol_spec_entry_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_reversal_marker, t_record_status, t_curr_no, t_inputter, t_date_time, t_authoriser)
WITH deduped AS (SELECT * FROM tmp_reconsol QUALIFY ROW_NUMBER() OVER (PARTITION BY re_consol_spec_entry_hashkey, hd_audit ORDER BY data_date) = 1)
SELECT d.re_consol_spec_entry_hashkey, d.hd_audit, d.source_event_date, current_timestamp(), 't24__t24_re_consol_spec_entry',
       d.t_reversal_marker, d.t_record_status, d.t_curr_no, d.t_inputter, d.t_date_time, d.t_authoriser
FROM deduped d LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_audit t
    ON t.re_consol_spec_entry_hashkey = d.re_consol_spec_entry_hashkey AND t.hashdiff = d.hd_audit;

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_information
(re_consol_spec_entry_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_amount_lcy, t_narrative, t_value_date, t_amount_fcy, t_exchange_rate,
 t_our_reference, t_local_ref, t_trans_reference, t_booking_date, t_stmt_no, t_currency)
WITH deduped AS (SELECT * FROM tmp_reconsol QUALIFY ROW_NUMBER() OVER (PARTITION BY re_consol_spec_entry_hashkey, hd_information ORDER BY data_date) = 1)
SELECT d.re_consol_spec_entry_hashkey, d.hd_information, d.source_event_date, current_timestamp(), 't24__t24_re_consol_spec_entry',
       d.t_amount_lcy, d.t_narrative, d.t_value_date, d.t_amount_fcy, d.t_exchange_rate,
       d.t_our_reference, d.t_local_ref, d.t_trans_reference, d.t_booking_date, d.t_stmt_no, d.t_currency
FROM deduped d LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_information t
    ON t.re_consol_spec_entry_hashkey = d.re_consol_spec_entry_hashkey AND t.hashdiff = d.hd_information;

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_classification
(re_consol_spec_entry_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_consol_key_type, t_pl_category, t_product_category, t_system_id, t_department_code, t_transaction_code)
WITH deduped AS (SELECT * FROM tmp_reconsol QUALIFY ROW_NUMBER() OVER (PARTITION BY re_consol_spec_entry_hashkey, hd_classification ORDER BY data_date) = 1)
SELECT d.re_consol_spec_entry_hashkey, d.hd_classification, d.source_event_date, current_timestamp(), 't24__t24_re_consol_spec_entry',
       d.t_consol_key_type, d.t_pl_category, d.t_product_category, d.t_system_id, d.t_department_code, d.t_transaction_code
FROM deduped d LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_re_consol_spec_entry_classification t
    ON t.re_consol_spec_entry_hashkey = d.re_consol_spec_entry_hashkey AND t.hashdiff = d.hd_classification;

DROP TEMPORARY TABLE IF EXISTS tmp_reconsol;
