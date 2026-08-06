-- Source: omni.od_linked_deposit | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_od_linked_deposit; CREATE TEMPORARY TABLE tmp_od_linked_deposit AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS od_linked_deposit_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(od_registration_id AS string))), ''), 256) AS od_registration_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(deposit_balance AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(maturity_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(opening_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_additional_request AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_by AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(updated_by AS string))), ''), 256) AS hd_od_linked_deposit_information,
    LEAST(CAST(UPDATED_AT AS DATE), CAST(CREATED_AT AS DATE)) AS source_event_date,
    id, CAST(id AS STRING) AS ma_key, deposit_balance, maturity_date, opening_date, is_additional_request,
    created_at, created_by, updated_at, updated_by,
    od_registration_id, deposit_account_no
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.od_linked_deposit')
WHERE LEAST(CAST(UPDATED_AT AS DATE), CAST(CREATED_AT AS DATE)) BETWEEN to_date({{start_date}}, 'yyyyMMdd') AND to_date({{end_date}}, 'yyyyMMdd')
  AND id IS NOT NULL;

-- SAT od_linked_deposit_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_od_linked_deposit_information')
(od_registration_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 ma_key, deposit_balance, maturity_date, opening_date, is_additional_request,
 created_at, created_by, updated_at, updated_by)
WITH deduped AS (
    SELECT * FROM tmp_od_linked_deposit
    QUALIFY ROW_NUMBER() OVER (PARTITION BY od_registration_hashkey, ma_key, hd_od_linked_deposit_information ORDER BY source_event_date) = 1
)
SELECT
    d.od_registration_hashkey AS od_registration_hashkey,
    d.hd_od_linked_deposit_information AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__od_linked_deposit' AS record_source,
    d.ma_key AS ma_key,
    d.deposit_balance AS deposit_balance,
    d.maturity_date AS maturity_date,
    d.opening_date AS opening_date,
    d.is_additional_request AS is_additional_request,
    d.created_at AS created_at,
    d.created_by AS created_by,
    d.updated_at AS updated_at,
    d.updated_by AS updated_by
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_od_linked_deposit_information') t
    ON t.od_registration_hashkey = d.od_registration_hashkey AND t.hashdiff = d.hd_od_linked_deposit_information;

DROP TEMPORARY TABLE IF EXISTS tmp_od_linked_deposit;
