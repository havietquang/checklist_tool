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
    alias = 'v_stg_t24_t24_ocbh_cu_add_inf_corp_vn',
    materialized = 'view',
    tags = ['t24', 'entity', 'phase2', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Tên hệ thống nguồn ('t24'), dùng để tạo
                            giá trị cho cột `record_source` ở downstream.
  - source_table          : Tên bảng nghiệp vụ nguồn ('t24_ocbh_cu_add_inf_corp_vn'),
                            dùng để map đúng snapshot/source table.
  - business_key_cols     : Danh sách cột tạo thành Business Key duy nhất
                            của entity. ['id'] = mã khách hàng T24.
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
{% set source_table = "t24_ocbh_cu_add_inf_corp_vn" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_cu_add_inf_corp_vn': ['t_rep_address', 't_rep_ward', 't_rep_dist', 't_rep_city', 't_legrep_is_acrep', 't_acrep_nat', 't_acrep_name', 't_acrep_job', 't_acrep_doc', 't_acrep_id', 't_acrep_dob', 't_acrep_phone', 't_acrep_email', 't_acrep_addr', 't_acrep_ward', 't_acrep_dist', 't_acrep_city', 't_ceo_name', 't_ceo_nation', 't_ceo_job', 't_ceo_doc', 't_ceo_id', 't_ceo_addr', 't_ceo_ward', 't_ceo_dist', 't_ceo_city', 't_capital_ccy', 't_rep_residence', 't_rep_visa_no', 't_rep_lg_iss_dep', 't_rep_lg_exp_dep', 't_rep_lg_pla_dep', 't_acrep_residence', 't_acrep_legal_iss', 't_acrep_legal_exp', 't_acrep_legal_pla', 't_ceo_residence', 't_ceo_visa_no', 't_ceo_iss_date', 't_ceo_exp_date', 't_ceo_legal_place', 't_acc_nation', 't_acc_residence', 't_acc_name', 't_acc_title', 't_acc_visa_no', 't_acc_job_title', 't_acc_legal_id', 't_acc_legal_type', 't_acc_iss_date', 't_acc_exp_date', 't_acc_legal_place', 't_acc_birth_date', 't_acc_phone', 't_acc_email', 't_ocb_indus_tt15', 't_ocb_visa_type', 't_rep_visa_exp', 't_acrep_visa_exp', 't_ceo_visa_exp', 't_acc_visa_exp', 't_acrep_visa_no'],
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
