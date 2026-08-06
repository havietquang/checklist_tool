/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/

{{ config(
    alias = 'v_stg_t24_t24_az_account',
    materialized = 'view',
    tags = ['t24', 'deposit', 'phase2', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_az_account'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('data_date'),
                            dung lam source_event_date o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name = 't24' -%}
{% set source_table = "t24_az_account" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_deposits_classification': ['t_deposit_prgm', 't_all_in_one_product', 't_category', 't_roll_aio_product', 't_preclose_reason', 't_waive_chg'],
    'hashdiff_deposits_ftp': ['t_ocb_ftp_bd_type', 't_ocb_ftp_callput', 't_ocb_ftp_frdate', 't_ocb_ftp_tright', 't_ocb_ftp_vlpaper', 't_ocb_ftp_cifcoll'],
    'hashdiff_deposits_information': ['t_currency', 't_value_date', 't_maturity_date', 't_create_date', 't_principal', 't_orig_principal', 't_rollover_date', 't_ocb_term_commit', 't_ocb_mat_dt_comm', 't_ocb_id_hotro', 't_ocb_loyal_intr', 't_record_status'],
    'hashdiff_deposits_rate': ['t_interest_rate', 't_sch_fixed_rate', 't_org_int_rate', 't_rollover_int_rate', 't_calculation_base', 't_pay_int_at_mat', 't_early_rate', 't_early_red_int', 't_ocb_auth_level', 't_ocb_ipre_date', 't_ocb_intratetype'],
    'hashdiff_deposits_system': ['t_inputter', 't_authoriser', 't_date_time', 't_trans_unique_id', 't_curr_no', 't_dept_code'],
    'hashdiff_deposits_terms': ['t_term', 't_rollover_term', 't_type_of_schdle', 't_frequency', 't_maturity_instr', 't_schedules', 't_forward_backward'],
}
-%}

/*
------------------------------------------------------------------------
STAGE MACRO CALL
------------------------------------------------------------------------
Guard `if execute` ngan macro chay luc dbt parse/compile
(tranh loi khi chua co context thuc thi).
Macro `stage()` se sinh ra cau SELECT day du gom:
  - Tat ca cot goc tu source
  - Cot hashkey (hash cua business_key_cols)
  - Cac cot hashdiff theo hashdiff_satellite_dict
  - Cot record_source, source_event_date, load_timestamp
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
