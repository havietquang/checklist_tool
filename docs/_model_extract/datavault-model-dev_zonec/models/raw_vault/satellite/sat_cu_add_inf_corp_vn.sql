/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record mới/thay đổi
                    : 'table' = full load
                    : 'view' = chỉ tạo view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chỉ insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khóa định danh record (thường: hub_hashkey + hashdiff)
skip_matched_step   : true = bỏ record không đổi → tăng performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/

{{ config(
    alias = 'sat_cu_add_inf_corp_vn',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['customer_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'entity', 'phase2', 'all']
) }}

/*
========================================================================
SATELLITE MACRO PARAMETERS
========================================================================
  - source_name         : Tên hệ thống nguồn, dùng để tạo giá trị cho cột `record_source`.
  - source_table        : Tên bảng nghiệp vụ ở hệ thống nguồn.
  - hashdiff_col        : Tên cột hashdiff đã được tính sẵn ở tầng staging.
  - hub_hashkey         : Tên khóa hash dùng để liên kết về bảng Hub.
  - source_model        : Model staging làm nguồn để đọc dữ liệu.
  - list_cols           : Danh sách các cột nghiệp vụ được lưu trong Satellite.
  - raw_sql (optional)  : Câu SQL tự viết trong trường hợp logic phức tạp hoặc đặc biệt.
*/

{% set source_name = 't24' %}
{% set source_table = 't24_ocbh_cu_add_inf_corp_vn' %}
{% set hashdiff_col = 'hashdiff_cu_add_inf_corp_vn' %}
{% set hub_hashkey = 'customer_hashkey' %}
{% set source_model = 'v_stg_t24_t24_ocbh_cu_add_inf_corp_vn' %}
{% set list_cols = ['t_rep_address', 't_rep_ward', 't_rep_dist', 't_rep_city', 't_legrep_is_acrep', 't_acrep_nat', 't_acrep_name', 't_acrep_job', 't_acrep_doc', 't_acrep_id', 't_acrep_dob', 't_acrep_phone', 't_acrep_email', 't_acrep_addr', 't_acrep_ward', 't_acrep_dist', 't_acrep_city', 't_ceo_name', 't_ceo_nation', 't_ceo_job', 't_ceo_doc', 't_ceo_id', 't_ceo_addr', 't_ceo_ward', 't_ceo_dist', 't_ceo_city', 't_capital_ccy', 't_rep_residence', 't_rep_visa_no', 't_rep_lg_iss_dep', 't_rep_lg_exp_dep', 't_rep_lg_pla_dep', 't_acrep_residence', 't_acrep_legal_iss', 't_acrep_legal_exp', 't_acrep_legal_pla', 't_ceo_residence', 't_ceo_visa_no', 't_ceo_iss_date', 't_ceo_exp_date', 't_ceo_legal_place', 't_acc_nation', 't_acc_residence', 't_acc_name', 't_acc_title', 't_acc_visa_no', 't_acc_job_title', 't_acc_legal_id', 't_acc_legal_type', 't_acc_iss_date', 't_acc_exp_date', 't_acc_legal_place', 't_acc_birth_date', 't_acc_phone', 't_acc_email', 't_ocb_indus_tt15', 't_ocb_visa_type', 't_rep_visa_exp', 't_acrep_visa_exp', 't_ceo_visa_exp', 't_acc_visa_exp', 't_acrep_visa_no'] %}
{% set raw_sql = None %}

/*
Truong hop khong su dung marco satellite, co the su dung raw_sql nhu ben duoi de
viet SQL thu cong, sau do truyen vao macro satellite de tao satellite
*/
{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
