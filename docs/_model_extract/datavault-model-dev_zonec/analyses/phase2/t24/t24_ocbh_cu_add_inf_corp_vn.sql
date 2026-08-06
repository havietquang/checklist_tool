-- Source: .t24.t24_ocbh_cu_add_inf_corp_vn
-- Target: :catalog_cleaned.raw_vault
--   sat_cu_add_inf_corp_vn
-- Range: 20250101 -> 20250131
DROP TEMPORARY TABLE IF EXISTS tmp_t24_ocbh_cu_add_inf_corp_vn; CREATE TEMPORARY TABLE tmp_t24_ocbh_cu_add_inf_corp_vn AS
SELECT
    sha2(COALESCE(UPPER(TRIM(CAST(id AS string))), ''), 256) AS customer_hashkey,
    sha2(COALESCE(UPPER(TRIM(CAST(t_rep_address AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rep_ward AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rep_dist AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rep_city AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_legrep_is_acrep AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_nat AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_job AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_doc AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_dob AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_phone AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_email AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_addr AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_ward AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_dist AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_city AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_nation AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_job AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_doc AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_addr AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_ward AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_dist AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_city AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_capital_ccy AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rep_residence AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rep_visa_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rep_lg_iss_dep AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rep_lg_exp_dep AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rep_lg_pla_dep AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_residence AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_legal_iss AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_legal_exp AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_legal_pla AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_residence AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_visa_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_iss_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_exp_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_legal_place AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_nation AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_residence AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_name AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_title AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_visa_no AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_job_title AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_legal_id AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_legal_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_iss_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_exp_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_legal_place AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_birth_date AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_phone AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_email AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ocb_indus_tt15 AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ocb_visa_type AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_rep_visa_exp AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_visa_exp AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_ceo_visa_exp AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acc_visa_exp AS string))), '') || '$' ||
         COALESCE(UPPER(TRIM(CAST(t_acrep_visa_no AS string))), ''), 256) AS hd_cu_add_inf_corp_vn,
    data_date, to_date(data_date, 'yyyyMMdd') AS source_event_date,
    id,
    t_rep_address, t_rep_ward, t_rep_dist, t_rep_city, t_legrep_is_acrep,
    t_acrep_nat, t_acrep_name, t_acrep_job, t_acrep_doc, t_acrep_id, t_acrep_dob,
    t_acrep_phone, t_acrep_email, t_acrep_addr, t_acrep_ward, t_acrep_dist, t_acrep_city,
    t_ceo_name, t_ceo_nation, t_ceo_job, t_ceo_doc, t_ceo_id, t_ceo_addr,
    t_ceo_ward, t_ceo_dist, t_ceo_city, t_capital_ccy,
    t_rep_residence, t_rep_visa_no, t_rep_lg_iss_dep, t_rep_lg_exp_dep, t_rep_lg_pla_dep,
    t_acrep_residence, t_acrep_legal_iss, t_acrep_legal_exp, t_acrep_legal_pla,
    t_ceo_residence, t_ceo_visa_no, t_ceo_iss_date, t_ceo_exp_date, t_ceo_legal_place,
    t_acc_nation, t_acc_residence, t_acc_name, t_acc_title, t_acc_visa_no,
    t_acc_job_title, t_acc_legal_id, t_acc_legal_type, t_acc_iss_date, t_acc_exp_date,
    t_acc_legal_place, t_acc_birth_date, t_acc_phone, t_acc_email,
    t_ocb_indus_tt15, t_ocb_visa_type,
    t_rep_visa_exp, t_acrep_visa_exp, t_ceo_visa_exp, t_acc_visa_exp, t_acrep_visa_no
FROM IDENTIFIER({{catalog_sourcing}} || '.t24.t24_ocbh_cu_add_inf_corp_vn')
WHERE data_date BETWEEN {{start_date}} AND {{end_date}} AND id IS NOT NULL;

-- [sat_cu_add_inf_corp_vn] Insert new attribute snapshots (compare with latest per hashkey)
INSERT INTO IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_cu_add_inf_corp_vn')
(customer_hashkey, hashdiff, source_event_date, load_timestamp, record_source,
 t_rep_address, t_rep_ward, t_rep_dist, t_rep_city, t_legrep_is_acrep,
 t_acrep_nat, t_acrep_name, t_acrep_job, t_acrep_doc, t_acrep_id, t_acrep_dob,
 t_acrep_phone, t_acrep_email, t_acrep_addr, t_acrep_ward, t_acrep_dist, t_acrep_city,
 t_ceo_name, t_ceo_nation, t_ceo_job, t_ceo_doc, t_ceo_id, t_ceo_addr,
 t_ceo_ward, t_ceo_dist, t_ceo_city, t_capital_ccy,
 t_rep_residence, t_rep_visa_no, t_rep_lg_iss_dep, t_rep_lg_exp_dep, t_rep_lg_pla_dep,
 t_acrep_residence, t_acrep_legal_iss, t_acrep_legal_exp, t_acrep_legal_pla,
 t_ceo_residence, t_ceo_visa_no, t_ceo_iss_date, t_ceo_exp_date, t_ceo_legal_place,
 t_acc_nation, t_acc_residence, t_acc_name, t_acc_title, t_acc_visa_no,
 t_acc_job_title, t_acc_legal_id, t_acc_legal_type, t_acc_iss_date, t_acc_exp_date,
 t_acc_legal_place, t_acc_birth_date, t_acc_phone, t_acc_email,
 t_ocb_indus_tt15, t_ocb_visa_type,
 t_rep_visa_exp, t_acrep_visa_exp, t_ceo_visa_exp, t_acc_visa_exp, t_acrep_visa_no)
WITH last_known AS (
    SELECT customer_hashkey, hashdiff AS last_hashdiff
    FROM IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_cu_add_inf_corp_vn')
    WHERE source_event_date < to_date({{start_date}}, 'yyyyMMdd')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_hashkey ORDER BY source_event_date DESC) = 1
),
ordered AS (
    SELECT s.*,
           COALESCE(
               LAG(s.hd_cu_add_inf_corp_vn) OVER (PARTITION BY s.customer_hashkey ORDER BY s.data_date),
               lk.last_hashdiff
           ) AS prev_hashdiff
    FROM tmp_t24_ocbh_cu_add_inf_corp_vn s
    LEFT JOIN last_known lk ON lk.customer_hashkey = s.customer_hashkey
),
change_events AS (SELECT * FROM ordered WHERE prev_hashdiff IS NULL OR hd_cu_add_inf_corp_vn != prev_hashdiff)
SELECT d.customer_hashkey, d.hd_cu_add_inf_corp_vn, d.source_event_date, current_timestamp(), 't24__t24_ocbh_cu_add_inf_corp_vn',
       d.t_rep_address, d.t_rep_ward, d.t_rep_dist, d.t_rep_city, d.t_legrep_is_acrep,
       d.t_acrep_nat, d.t_acrep_name, d.t_acrep_job, d.t_acrep_doc, d.t_acrep_id, d.t_acrep_dob,
       d.t_acrep_phone, d.t_acrep_email, d.t_acrep_addr, d.t_acrep_ward, d.t_acrep_dist, d.t_acrep_city,
       d.t_ceo_name, d.t_ceo_nation, d.t_ceo_job, d.t_ceo_doc, d.t_ceo_id, d.t_ceo_addr,
       d.t_ceo_ward, d.t_ceo_dist, d.t_ceo_city, d.t_capital_ccy,
       d.t_rep_residence, d.t_rep_visa_no, d.t_rep_lg_iss_dep, d.t_rep_lg_exp_dep, d.t_rep_lg_pla_dep,
       d.t_acrep_residence, d.t_acrep_legal_iss, d.t_acrep_legal_exp, d.t_acrep_legal_pla,
       d.t_ceo_residence, d.t_ceo_visa_no, d.t_ceo_iss_date, d.t_ceo_exp_date, d.t_ceo_legal_place,
       d.t_acc_nation, d.t_acc_residence, d.t_acc_name, d.t_acc_title, d.t_acc_visa_no,
       d.t_acc_job_title, d.t_acc_legal_id, d.t_acc_legal_type, d.t_acc_iss_date, d.t_acc_exp_date,
       d.t_acc_legal_place, d.t_acc_birth_date, d.t_acc_phone, d.t_acc_email,
       d.t_ocb_indus_tt15, d.t_ocb_visa_type,
       d.t_rep_visa_exp, d.t_acrep_visa_exp, d.t_ceo_visa_exp, d.t_acc_visa_exp, d.t_acrep_visa_no
FROM change_events d
LEFT ANTI JOIN IDENTIFIER({{catalog_cleaned}} || '.raw_vault.sat_cu_add_inf_corp_vn') t ON t.customer_hashkey = d.customer_hashkey AND t.source_event_date = d.source_event_date;

DROP TEMPORARY TABLE IF EXISTS tmp_t24_ocbh_cu_add_inf_corp_vn;
