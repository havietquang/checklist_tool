-- Source: t24_line_mvmt_toanhang | Full range 20230209 → 20260602
DECLARE OR REPLACE VARIABLE start_date STRING DEFAULT '20230209';
DECLARE OR REPLACE VARIABLE end_date   STRING DEFAULT '20260602';

INSERT INTO ocb_datavault_prod_cleaned.raw_vault.sat_line_movement_toanhang
(line_movement_toanhang_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_y_trans_code, t_amount_lcy, t_amount_fcy, t_ccy, t_consol_key,
 t_y_xref_rev_marker, t_y_dr_cr, t_y_xref_booking_date, t_y_xref_value_date,
 t_y_xref_accounting_date, t_xref_nxt_version, t_stt)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(t_line_id AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t_stt     AS string))), ''), 256) AS line_movement_toanhang_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(t_y_trans_code           AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t_amount_lcy             AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t_amount_fcy             AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t_ccy                    AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t_consol_key             AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t_y_xref_rev_marker      AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t_y_dr_cr                AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t_y_xref_booking_date    AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t_y_xref_value_date      AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t_y_xref_accounting_date AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t_xref_nxt_version       AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(t_stt                    AS string))), ''), 256) AS hashdiff,
        data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
        t_y_trans_code, t_amount_lcy, t_amount_fcy, t_ccy, t_consol_key,
        t_y_xref_rev_marker, t_y_dr_cr, t_y_xref_booking_date, t_y_xref_value_date,
        t_y_xref_accounting_date, t_xref_nxt_version, t_stt
    FROM ocb_datavault_prod_sourcing.t24.t24_line_mvmt_toanhang
    WHERE data_date BETWEEN start_date AND end_date
      AND t_line_id IS NOT NULL AND t_stt IS NOT NULL
),
deduped AS (
    SELECT * FROM src
    QUALIFY ROW_NUMBER() OVER (PARTITION BY line_movement_toanhang_hashkey, hashdiff ORDER BY data_date) = 1
)
SELECT d.line_movement_toanhang_hashkey, d.hashdiff, d.source_event_date,
       current_timestamp(), 't24__t24_line_mvmt_toanhang',
       d.t_y_trans_code, d.t_amount_lcy, d.t_amount_fcy, d.t_ccy, d.t_consol_key,
       d.t_y_xref_rev_marker, d.t_y_dr_cr, d.t_y_xref_booking_date, d.t_y_xref_value_date,
       d.t_y_xref_accounting_date, d.t_xref_nxt_version, d.t_stt
FROM deduped d LEFT ANTI JOIN ocb_datavault_prod_cleaned.raw_vault.sat_line_movement_toanhang t
    ON t.line_movement_toanhang_hashkey = d.line_movement_toanhang_hashkey AND t.hashdiff = d.hashdiff;
