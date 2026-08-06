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
    alias = 'v_stg_t24_t24_standing_order',
    materialized = 'view',
    tags = ['t24', 'transaction', 'phase2', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Tên hệ thống nguồn ('t24'), dùng để tạo
                            giá trị cho cột `record_source` ở downstream.
  - source_table          : Tên bảng nghiệp vụ nguồn ('t24_standing_order'),
                            dùng để map đúng snapshot/source table.
  - business_key_cols     : Danh sách cột tạo thành Business Key duy nhất
                            của entity. ['id'] = mã lệnh thanh toán định kỳ T24.
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
{% set source_table = "t24_standing_order" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_standing_order': ['t_currency', 't_payment_details', 't_type', 't_pay_method', 't_current_amount_bal', 't_ordering_cust', 't_debit_customer', 't_credit_customer', 't_cpty_acct_no', 't_co_code', 't_acct_officer'],
    'hashdiff_standing_order_dynamic': ['t_current_frequency', 't_curr_freq_date', 't_current_end_date', 't_inputter', 't_authoriser', 't_last_run_date']
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
