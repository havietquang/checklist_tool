/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record (thuong: hub_hashkey + hashdiff)
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/

{{ config(
    alias = 'sat_user_other',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['user_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['t24', 'entity', 'phase1', 'all']
) }}

/*
========================================================================
SATELLITE MACRO PARAMETERS
========================================================================
  - source_name         : Ten he thong nguon, dung de tao gia tri cho cot `record_source`.
  - source_table        : Ten bang nghiep vu o he thong nguon.
  - hashdiff_col        : Ten cot hashdiff da duoc tinh san o tang staging.
  - hub_hashkey         : Ten khoa hash dung de lien ket ve bang Hub.
  - source_model        : Model staging lam nguon de doc du lieu.
  - list_cols           : Danh sach cac cot nghiep vu duoc luu trong Satellite.
  - raw_sql (optional)  : Cau SQL tu viet trong truong hop logic phuc tap hoac dac biet.
========================================================================
*/

{% set source_name = 't24' %}
{% set source_table = 't24_user' %}
{% set hashdiff_col = 'hashdiff_user_other' %}
{% set hub_hashkey = 'user_hashkey' %}
{% set source_model = 'v_stg_t24_t24_user' %}
{% set list_cols = ['t_password_validity','t_attempts','t_customer','t_account','t_application','t_version','t_function','t_field_no','t_data_comparison','t_data_from','t_data_to','t_sign_on_off_log','t_security_mgmt_l','t_application_log','t_function_id_log','t_input_day_month','t_attempts_since','t_date_last_sign_on','t_clear_screen','t_dealer_desk','t_comp_report','t_ocb_department'] %}
{% set raw_sql = None %}


/*
Truong hop khong su dung macro satellite, co the su dung raw_sql nhu ben duoi de
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

