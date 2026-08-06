-- Source: .t24.t24_comp_level_group
-- Target: :catalog_cleaned.raw_vault
--   sat_branch_comp_level_group
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_comp_level_group; CREATE TEMPORARY TABLE tmp_t24_comp_level_group AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS branch_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_level2_comp AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_lead_company AS string))), ''), 256) AS hd_branch_comp_level_group,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_description, t_level2_comp, t_lead_company
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_comp_level_group')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [sat_branch_comp_level_group] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_branch_comp_level_group')
(branch_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_description, t_level2_comp, t_lead_company)
WITH last_known AS (
    SELECT branch_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_branch_comp_level_group')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY branch_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_branch_comp_level_group) OVER (PARTITION BY s.branch_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_comp_level_group s
    LEFT JOIN last_known lk ON lk.branch_hashkey = s.branch_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_branch_comp_level_group != prev_hashdiff)
SELECT d.branch_hashkey, d.hd_branch_comp_level_group, d.source_event_date, current_timestamp(), 't24__t24_comp_level_group',
       d.t_description, d.t_level2_comp, d.t_lead_company
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_branch_comp_level_group') t ON t.branch_hashkey = d.branch_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_comp_level_group;
