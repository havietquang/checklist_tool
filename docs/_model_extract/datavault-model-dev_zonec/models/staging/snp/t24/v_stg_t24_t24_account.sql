/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chỉ tạo view, không lưu dữ liệu vật lý.
               Staging luôn dùng view để đảm bảo dữ liệu mới nhất
               từ source được đọc trực tiếp mỗi khi downstream
               model chạy.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/
{{ config(
    alias = 'v_stg_t24_t24_account',
    materialized = 'view',
    tags = ['t24', 'account', 'crb', 'phase2', 'phase1', 'all', 'bv_zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Tên hệ thống nguồn ('t24'), dùng để tạo
                            giá trị cho cột `record_source` ở downstream.
  - source_table          : Tên bảng nghiệp vụ nguồn ('t24_account'),
                            dùng để map đúng snapshot/source table.
  - business_key_cols     : Danh sách cột tạo thành Business Key duy nhất
                            của entity. ['id'] = mã tài khoản T24.
                            Macro sẽ hash các cột này thành hashkey.
  - source_event_date_col : Cột ngày sự kiện từ nguồn ('data_date'),
                            dùng làm `source_event_date` ở downstream.
  - hashdiff_satellite_dict: Dictionary ánh xạ tên hashdiff → danh sách
                            cột tương ứng. Mỗi entry sinh ra một cột
                            hashdiff riêng, phục vụ một Satellite riêng
                            biệt ở tầng raw_vault.
========================================================================
*/
{% set source_name = 't24' -%}
{% set source_table = "t24_account" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_account_balance': ['t_interest_rate', 't_currency', 't_open_actual_bal', 't_online_actual_bal', 't_working_balance', 't_locked_amount', 't_date_last_cr_cust', 't_date_last_dr_cust', 't_amnt_last_cr_cust', 't_amnt_last_dr_cust'],
    'hashdiff_account_other': ['t_open_cleared_bal', 't_online_cleared_bal', 't_int_balance', 't_ref_officer', 't_master_account', 't_int_liqu_acct', 't_accr_dr_amount', 't_dpi_fin_date', 't_tran_last_cr_cust', 't_tran_last_dr_cust'],
    'hashdiff_account_classification': ['t_category', 't_sub_product', 't_pl_cate', 't_cust_group', 't_condition_group', 't_limit_ref', 't_cb_package_id'],
    'hashdiff_account_information': ['t_account_title_1', 't_account_title_2', 't_short_title', 't_opening_date', 't_create_date', 't_mature_date', 't_value_date', 't_term_xau', 't_posting_restrict', 't_record_status', 't_alt_acct_id', 't_joint_holder', 't_arrangement_id', 't_source_of_fund', 't_ocb_beauty_sts'],
    'hashdiff_account_system': ['t_inputter', 't_authoriser', 't_date_time', 't_date_last_update', 't_package_date', 't_curr_no', 't_ocb_reason_rest'],
}
-%}

/*
------------------------------------------------------------------------
STAGE MACRO CALL
------------------------------------------------------------------------
Guard `if execute` ngăn macro chạy lúc dbt parse/compile
(tránh lỗi khi chưa có context thực thi).
Macro `stage()` sẽ sinh ra câu SELECT đầy đủ gồm:
  - Tất cả cột gốc từ source
  - Cột hashkey (hash của business_key_cols)
  - Các cột hashdiff theo hashdiff_satellite_dict
  - Cột record_source, source_event_date, load_timestamp
------------------------------------------------------------------------
*/
{% if execute -%}
{{ stage(source_table=source_table
        ,business_key_cols=business_key_cols
        ,hashdiff_satellite_dict=hashdiff_satellite_dict
        ,source_event_date_col=source_event_date_col
        ,source_event_date_dttype=source_event_date_dttype
        ,source_name=source_name
        )
}}
{% endif -%}
