-- Source: omni.onboarding_report | Range: 20250101 → 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_onboarding_report; CREATE TEMPORARY TABLE tmp_onboarding_report AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(case_key AS string))), ''), 256) AS onboarding_report_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(step_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(report_data AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(phone_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(email AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(identity_number AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(full_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(created_at AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(modified_at AS string))), ''), 256) AS hd_onboarding_information,
    CAST(MODIFIED_AT AS DATE) AS source_event_date,
    case_key, step_name, report_data, phone_number, email, identity_number, full_name,
    created_at, modified_at
FROM IDENTIFIER({{catalog_sourcing}} || '.omni.onboarding_report')
WHERE CAST(MODIFIED_AT AS DATE) BETWEEN to_date({{start_date}}, 'yyyyMMdd') AND to_date({{end_date}}, 'yyyyMMdd')
  AND case_key IS NOT NULL;

-- SAT onboarding_information
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_onboarding_information')
(onboarding_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 step_name, report_data, phone_number, email, identity_number, full_name, created_at, modified_at)
WITH deduped AS (
    SELECT * FROM tmp_onboarding_report
    QUALIFY ROW_NUMBER() OVER (PARTITION BY onboarding_report_hashkey, hd_onboarding_information ORDER BY source_event_date) = 1
)
SELECT
    d.onboarding_report_hashkey AS onboarding_hashkey,
    d.hd_onboarding_information AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'omni__onboarding_report' AS record_source,
    d.step_name AS step_name,
    d.report_data AS report_data,
    d.phone_number AS phone_number,
    d.email AS email,
    d.identity_number AS identity_number,
    d.full_name AS full_name,
    d.created_at AS created_at,
    d.modified_at AS modified_at
FROM deduped d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_onboarding_information') t
    ON t.onboarding_hashkey = d.onboarding_report_hashkey AND t.hashdiff = d.hd_onboarding_information;

DROP TEMPORARY TABLE IF EXISTS tmp_onboarding_report;
