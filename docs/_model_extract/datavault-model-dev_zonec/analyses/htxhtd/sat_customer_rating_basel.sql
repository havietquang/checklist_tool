-- Source: .t24.t24_customer
-- Target: :catalog_cleaned.raw_vault
--   sat_customer_rating_basel
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_customer_rating_basel; CREATE TEMPORARY TABLE tmp_t24_customer_rating_basel AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS customer_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(fitch_rtg_form AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sp_rtg_form AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(moody_rtg_form AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sp_rating AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(fitch_rating AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(moody_rating AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(sp_rating_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(fitch_rtg_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(moody_rtg_date AS string))), ''), 256) AS hd_customer_rating_basel,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    fitch_rtg_form, sp_rtg_form, moody_rtg_form, sp_rating, fitch_rating, moody_rating,
    sp_rating_date, fitch_rtg_date, moody_rtg_date
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_customer')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [sat_customer_rating_basel] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_customer_rating_basel')
(customer_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 fitch_rtg_form, sp_rtg_form, moody_rtg_form, sp_rating, fitch_rating, moody_rating,
 sp_rating_date, fitch_rtg_date, moody_rtg_date)
WITH last_known AS (
    SELECT customer_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_customer_rating_basel')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_customer_rating_basel) OVER (PARTITION BY s.customer_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_customer_rating_basel s
    LEFT JOIN last_known lk ON lk.customer_hashkey = s.customer_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_customer_rating_basel != prev_hashdiff)
SELECT d.customer_hashkey, d.hd_customer_rating_basel, d.source_event_date, current_timestamp(), 't24__t24_customer',
       d.fitch_rtg_form, d.sp_rtg_form, d.moody_rtg_form, d.sp_rating, d.fitch_rating, d.moody_rating,
       d.sp_rating_date, d.fitch_rtg_date, d.moody_rtg_date
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_customer_rating_basel') t ON t.customer_hashkey = d.customer_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_customer_rating_basel;
