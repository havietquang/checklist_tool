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
    alias = 'sat_collateral_real_estate',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['collateral_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'collateral', 'phase1', 'all']
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
{% set source_table = 't24_collateral' %}
{% set hashdiff_col = 'hashdiff_collateral_real_estate' %}
{% set hub_hashkey = 'collateral_hashkey' %}
{% set source_model = 'v_stg_t24_t24_collateral' %}
{% set list_cols = ['t_houseprj_cb AS t_houseprj_cb', 't_ocb_project_nam AS t_ocb_project_nam', 't_ocb_project_inv AS t_ocb_project_inv', 't_ocb_tot_vl_inve AS t_ocb_tot_vl_inve', 't_ocb_pr_end_date AS t_ocb_pr_end_date', 't_ocb_rec_est_dat AS t_ocb_rec_est_dat', 't_ocb_lea_est_dat AS t_ocb_lea_est_dat', 't_ocb_issuer AS t_ocb_issuer', 't_ocb_parcel_num AS t_ocb_parcel_num', 't_ocb_map_num AS t_ocb_map_num', 't_country AS t_country', 't_province_2 AS t_province_2', 't_town_country_2 AS t_town_country_2', 't_ward_2 AS t_ward_2', 't_add_num AS t_add_num', 't_address AS t_address'] %}
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

