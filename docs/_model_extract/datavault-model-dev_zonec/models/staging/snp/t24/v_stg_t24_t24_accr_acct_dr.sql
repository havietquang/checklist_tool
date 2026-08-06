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
    alias = 'v_stg_t24_t24_accr_acct_dr',
    materialized = 'view',
    tags = ['t24', 'account', 'phase2', 'all', 'bv_zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Tên hệ thống nguồn ('t24'), dùng để tạo
                            giá trị cho cột `record_source` ở downstream.
  - source_table          : Tên bảng nghiệp vụ nguồn ('t24_accr_acct_dr'),
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
{% set source_table = "t24_accr_acct_dr" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_accr_acct_dr_information': ['t_liquidity_ccy', 't_period_first_date', 't_dr_int_rate', 't_dr_int_date', 't_dr_int_amt', 't_dr_int_categ', 't_dr_val_balance', 't_dr_int_tr_ac', 't_dr_int_tr_pl', 't_total_interest'],
    'hashdiff_accr_acct_dr_dynamic': ['t_period_last_date', 't_dr_no_of_days'],
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
