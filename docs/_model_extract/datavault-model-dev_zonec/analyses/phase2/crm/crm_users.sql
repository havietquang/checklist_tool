-- ============================================================
-- Source table  : .crm.crm_users
-- Target tables : hub_crm_users
--                 sat_crm_users_information
--                 sat_crm_users_other
--                 link_crm_users_branch
--                 link_crm_users_dept_acct_officer
-- Date range    : fullload {{start_date}}=20250101
-- ============================================================

DROP TEMPORARY TABLE IF EXISTS tmp_crm_users; CREATE TEMPORARY TABLE tmp_crm_users AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(user_id AS string))), ''), 256) AS crm_users_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(user_last_name        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(user_first_name       AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(user_full_name        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(user_status_id        AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_last_off         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(session_id            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(user_email            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(extension             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(language              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(user_phone            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(omni                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(telext                AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(branch_code           AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(custgroup             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(func_group            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(account_officer_id    AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(job_key               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(nearly_job_title      AS string))), ''), 256) AS hd_crm_users_information,
    sha2(COALESCE(UPPER(TRIM(CAST(is_team_manage             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(isactive                   AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(isdeleted                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_enable_market_place     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_lso_sk                  AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(is_out_of_line             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_custgroup              AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_branch_code            AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_user_full_name         AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_account_officer_id     AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_func_group             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_user_phone             AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(old_telext                 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(user_created               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_created               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(user_updated               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_updated               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(user_deleted               AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(date_deleted               AS string))), ''), 256) AS hd_crm_users_other,
    to_date({{start_date}}, 'yyyyMMdd') AS source_event_date,
    user_id,
    user_last_name, user_first_name, user_full_name, user_status_id, date_last_off, session_id,
    user_email, extension, language, user_phone, omni, telext, branch_code, custgroup,
    func_group, account_officer_id, job_key, nearly_job_title,
    is_team_manage, isactive, isdeleted, is_enable_market_place, is_lso_sk, is_out_of_line,
    old_custgroup, old_branch_code, old_user_full_name, old_account_officer_id, old_func_group,
    old_user_phone, old_telext, user_created, date_created, user_updated, date_updated,
    user_deleted, date_deleted
FROM IDENTIFIER({{catalog_sourcing}} || '.crm.crm_users')
WHERE user_id IS NOT NULL;

-- ============================================================
-- INSERT HUB
-- ============================================================
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_crm_users')
(crm_users_hashkey, business_key, source_event_date, load_timestamp, record_source)
WITH deduped AS (SELECT * FROM tmp_crm_users QUALIFY ROW_NUMBER() OVER (PARTITION BY crm_users_hashkey ORDER BY 1) = 1)
SELECT
    d.crm_users_hashkey AS crm_users_hashkey,
    CAST(d.user_id AS STRING) AS business_key,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'crm__crm_users' AS record_source
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.hub_crm_users') t
    ON t.crm_users_hashkey = d.crm_users_hashkey;

-- ============================================================
-- INSERT SATELLITE: sat_crm_users_information
-- ============================================================
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_crm_users_information')
(crm_users_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 user_last_name, user_first_name, user_full_name, user_status_id, date_last_off, session_id,
 user_email, extension, language, user_phone, omni, telext, branch_code, custgroup,
 func_group, account_officer_id, job_key, nearly_job_title)
WITH deduped AS (SELECT * FROM tmp_crm_users QUALIFY ROW_NUMBER() OVER (PARTITION BY crm_users_hashkey, hd_crm_users_information ORDER BY 1) = 1)
SELECT
    d.crm_users_hashkey AS crm_users_hashkey,
    d.hd_crm_users_information AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'crm__crm_users' AS record_source,
    d.user_last_name AS user_last_name,
    d.user_first_name AS user_first_name,
    d.user_full_name AS user_full_name,
    d.user_status_id AS user_status_id,
    d.date_last_off AS date_last_off,
    d.session_id AS session_id,
    d.user_email AS user_email,
    d.extension AS extension,
    d.language AS language,
    d.user_phone AS user_phone,
    d.omni AS omni,
    d.telext AS telext,
    d.branch_code AS branch_code,
    d.custgroup AS custgroup,
    d.func_group AS func_group,
    d.account_officer_id AS account_officer_id,
    d.job_key AS job_key,
    d.nearly_job_title AS nearly_job_title
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_crm_users_information') t
    ON t.crm_users_hashkey = d.crm_users_hashkey AND t.hashdiff = d.hd_crm_users_information;

-- ============================================================
-- INSERT SATELLITE: sat_crm_users_other
-- ============================================================
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_crm_users_other')
(crm_users_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 is_team_manage, isactive, isdeleted, is_enable_market_place, is_lso_sk, is_out_of_line,
 old_custgroup, old_branch_code, old_user_full_name, old_account_officer_id, old_func_group,
 old_user_phone, old_telext, user_created, date_created, user_updated, date_updated,
 user_deleted, date_deleted)
WITH deduped AS (SELECT * FROM tmp_crm_users QUALIFY ROW_NUMBER() OVER (PARTITION BY crm_users_hashkey, hd_crm_users_other ORDER BY 1) = 1)
SELECT
    d.crm_users_hashkey AS crm_users_hashkey,
    d.hd_crm_users_other AS hashdiff,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'crm__crm_users' AS record_source,
    d.is_team_manage AS is_team_manage,
    d.isactive AS isactive,
    d.isdeleted AS isdeleted,
    d.is_enable_market_place AS is_enable_market_place,
    d.is_lso_sk AS is_lso_sk,
    d.is_out_of_line AS is_out_of_line,
    d.old_custgroup AS old_custgroup,
    d.old_branch_code AS old_branch_code,
    d.old_user_full_name AS old_user_full_name,
    d.old_account_officer_id AS old_account_officer_id,
    d.old_func_group AS old_func_group,
    d.old_user_phone AS old_user_phone,
    d.old_telext AS old_telext,
    d.user_created AS user_created,
    d.date_created AS date_created,
    d.user_updated AS user_updated,
    d.date_updated AS date_updated,
    d.user_deleted AS user_deleted,
    d.date_deleted AS date_deleted
FROM deduped d LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_crm_users_other') t
    ON t.crm_users_hashkey = d.crm_users_hashkey AND t.hashdiff = d.hd_crm_users_other;

-- ============================================================
-- INSERT LINK: link_crm_users_branch
-- ============================================================
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_crm_users_branch')
(link_crm_users_branch_hashkey, crm_users_hashkey, branch_hashkey, source_event_date, load_timestamp, record_source)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(user_id     AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(branch_code AS string))), ''), 256) AS link_crm_users_branch_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(user_id     AS string))), ''), 256) AS crm_users_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(branch_code AS string))), ''), 256) AS branch_hashkey,
        source_event_date
    FROM tmp_crm_users
    WHERE user_id IS NOT NULL AND branch_code IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id, branch_code ORDER BY 1) = 1
)
SELECT
    d.link_crm_users_branch_hashkey AS link_crm_users_branch_hashkey,
    d.crm_users_hashkey AS crm_users_hashkey,
    d.branch_hashkey AS branch_hashkey,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'crm__crm_users' AS record_source
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_crm_users_branch') t
    ON t.link_crm_users_branch_hashkey = d.link_crm_users_branch_hashkey;

-- ============================================================
-- INSERT LINK: link_crm_users_dept_acct_officer
-- ============================================================
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_crm_users_dept_acct_officer')
(link_crm_users_dept_acct_officer_hashkey, crm_users_hashkey, dept_acct_officer_hashkey, source_event_date, load_timestamp, record_source)
WITH src AS (
    SELECT
        sha2(COALESCE(UPPER(TRIM(CAST(user_id            AS string))), '') || '$' ||
             COALESCE(UPPER(TRIM(CAST(account_officer_id AS string))), ''), 256) AS link_crm_users_dept_acct_officer_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(user_id            AS string))), ''), 256) AS crm_users_hashkey,
        sha2(COALESCE(UPPER(TRIM(CAST(account_officer_id AS string))), ''), 256) AS dept_acct_officer_hashkey,
        source_event_date
    FROM tmp_crm_users
    WHERE user_id IS NOT NULL AND account_officer_id IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id, account_officer_id ORDER BY 1) = 1
)
SELECT
    d.link_crm_users_dept_acct_officer_hashkey AS link_crm_users_dept_acct_officer_hashkey,
    d.crm_users_hashkey AS crm_users_hashkey,
    d.dept_acct_officer_hashkey AS dept_acct_officer_hashkey,
    d.source_event_date AS source_event_date,
    current_timestamp() AS load_timestamp,
    'crm__crm_users' AS record_source
FROM src d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.link_crm_users_dept_acct_officer') t
    ON t.link_crm_users_dept_acct_officer_hashkey = d.link_crm_users_dept_acct_officer_hashkey;

DROP TEMPORARY TABLE IF EXISTS tmp_crm_users;
