-- Source: .t24.t24_li_comp_level_right
-- Target: :catalog_cleaned.raw_vault
--   sat_branch_li_comp_level_right
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_li_comp_level_right; CREATE TEMPORARY TABLE tmp_t24_li_comp_level_right AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS branch_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_description AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_parent_company AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_currency AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_cust_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_amount AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_lead_company AS string))), ''), 256) AS hd_branch_li_comp_level_right,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_description, t_parent_company, t_currency, t_cust_type, t_amount, t_lead_company
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_li_comp_level_right')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [sat_branch_li_comp_level_right] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_branch_li_comp_level_right')
(branch_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_description, t_parent_company, t_currency, t_cust_type, t_amount, t_lead_company)
WITH last_known AS (
    SELECT branch_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_branch_li_comp_level_right')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY branch_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_branch_li_comp_level_right) OVER (PARTITION BY s.branch_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_li_comp_level_right s
    LEFT JOIN last_known lk ON lk.branch_hashkey = s.branch_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_branch_li_comp_level_right != prev_hashdiff)
SELECT d.branch_hashkey, d.hd_branch_li_comp_level_right, d.source_event_date, current_timestamp(), 't24__t24_li_comp_level_right',
       d.t_description, d.t_parent_company, d.t_currency, d.t_cust_type, d.t_amount, d.t_lead_company
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_branch_li_comp_level_right') t ON t.branch_hashkey = d.branch_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_li_comp_level_right;
