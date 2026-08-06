-- Source: t24_stmt_entry | Full range 20230209 → 20260602
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20230209';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260602';

DROP TEMPORARY TABLE IF EXISTS tmp_stmt; CREATE TEMPORARY TABLE tmp_stmt AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS stmt_entry_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_record_status   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_booking_date    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_inputter        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_authoriser      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_processing_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_exposure_date   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_date_time       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_reversal_marker AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_accounting_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_pc_period_end   AS string))), ''), 256) AS hd_audit,
    sha2(COALESCE(UPPER(TRIM(CAST(t_account_number  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amount_lcy      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_their_reference AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_value_date      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amount_fcy      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_exchange_rate   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_our_reference   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_trans_reference AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_currency        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_narrative       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_stmt_no         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_master_account  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_local_ref       AS string))), ''), 256) AS hd_information,
    sha2(COALESCE(UPPER(TRIM(CAST(t_pl_category      AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_product_category AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_crf_type         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_system_id        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_transaction_code AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_department_code  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_consol_key       AS string))), ''), 256) AS hd_classification,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    t_record_status, t_booking_date, t_inputter, t_authoriser, t_processing_date,
    t_exposure_date, t_date_time, t_reversal_marker, t_accounting_date, t_pc_period_end,
    t_account_number, t_amount_lcy, t_their_reference, t_value_date, t_amount_fcy,
    t_exchange_rate, t_our_reference, t_trans_reference, t_currency,
    t_narrative, t_stmt_no, t_master_account, t_local_ref,
    t_pl_category, t_product_category, t_crf_type, t_system_id, t_transaction_code, t_department_code, t_consol_key
FROM ocb_datavault_prod_sourcing.t24.t24_stmt_entry
WHERE data_date BETWEEN start_date AND end_date AND id IS NOT NULL;

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_audit
(stmt_entry_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_record_status, t_booking_date, t_inputter, t_authoriser, t_processing_date,
 t_exposure_date, t_date_time, t_reversal_marker, t_accounting_date, t_pc_period_end)
WITH deduped AS (SELECT * FROM tmp_stmt QUALIFY ROW_NUMBER() OVER (PARTITION BY stmt_entry_hashkey, hd_audit ORDER BY data_date) = 1)
SELECT d.stmt_entry_hashkey, d.hd_audit, d.source_event_date, current_timestamp(), 't24__t24_stmt_entry',
       d.t_record_status, d.t_booking_date, d.t_inputter, d.t_authoriser,
       d.t_processing_date, d.t_exposure_date, d.t_date_time,
       d.t_reversal_marker, d.t_accounting_date, d.t_pc_period_end
FROM deduped d LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_audit t
    ON t.stmt_entry_hashkey = d.stmt_entry_hashkey AND t.hashdiff = d.hd_audit;

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_information
(stmt_entry_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_account_number, t_amount_lcy, t_their_reference, t_value_date, t_amount_fcy,
 t_exchange_rate, t_our_reference, t_trans_reference, t_currency,
 t_narrative, t_stmt_no, t_master_account, t_local_ref)
WITH deduped AS (SELECT * FROM tmp_stmt QUALIFY ROW_NUMBER() OVER (PARTITION BY stmt_entry_hashkey, hd_information ORDER BY data_date) = 1)
SELECT d.stmt_entry_hashkey, d.hd_information, d.source_event_date, current_timestamp(), 't24__t24_stmt_entry',
       d.t_account_number, d.t_amount_lcy, d.t_their_reference, d.t_value_date,
       d.t_amount_fcy, d.t_exchange_rate, d.t_our_reference, d.t_trans_reference,
       d.t_currency, d.t_narrative, d.t_stmt_no, d.t_master_account, d.t_local_ref
FROM deduped d LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_information t
    ON t.stmt_entry_hashkey = d.stmt_entry_hashkey AND t.hashdiff = d.hd_information;

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_classification
(stmt_entry_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_pl_category, t_product_category, t_crf_type, t_system_id, t_transaction_code, t_department_code, t_consol_key)
WITH deduped AS (SELECT * FROM tmp_stmt QUALIFY ROW_NUMBER() OVER (PARTITION BY stmt_entry_hashkey, hd_classification ORDER BY data_date) = 1)
SELECT d.stmt_entry_hashkey, d.hd_classification, d.source_event_date, current_timestamp(), 't24__t24_stmt_entry',
       d.t_pl_category, d.t_product_category, d.t_crf_type,
       d.t_system_id, d.t_transaction_code, d.t_department_code, d.t_consol_key
FROM deduped d LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_stmt_entry_classification t
    ON t.stmt_entry_hashkey = d.stmt_entry_hashkey AND t.hashdiff = d.hd_classification;

DROP TEMPORARY TABLE IF EXISTS tmp_stmt;
