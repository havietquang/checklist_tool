/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias         : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags          : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/

{{ config(
    alias = 'v_stg_t24_t24_prod_package_cb',
    materialized = 'view',
    tags = ['t24', 'reference', 'phase2', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_prod_package_cb'),
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
{% set source_table = "t24_prod_package_cb" -%}
{% set business_key_cols = ['id'] -%}          
{% set list_cols = ['id', 't_package_name', 't_ac_manage_fee_per', 't_ext_ft_fee_per', 't_ib_fee_per', 't_tax_fee_per', 't_sms_fee_per', 't_record_status', 't_curr_no', 't_inputter', 't_date_time', 't_authoriser', 't_co_code', 't_dept_code', 't_package_fdate', 't_package_tdate', 't_ac_manage_fee_term', 't_ext_ft_fee_term', 't_ib_fee_term', 't_tax_fee_term', 't_sms_fee_term', 't_ac_min_avr_balance', 't_batch_ft_fee_per', 't_batch_ft_fee_term', 't_ft_8s_fee_per', 't_ft_8s_fee_term', 't_ext_fo_fee_per', 't_ext_fo_fee_term', 't_avr_balance_from', 't_avr_balance_to', 't_ac_manage_fee'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = None -%}

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
        ,list_cols=list_cols
        )
}}
{% endif -%}

