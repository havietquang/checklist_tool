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
    alias = 'v_stg_t24_t24_teller',
    materialized = 'view',
    tags = ['t24', 'transaction', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_teller'),
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
{% set source_table = "t24_teller" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_teller_information': ['t_dr_cr_marker', 't_currency_1', 't_amount_local_1', 't_amount_fcy_1', 't_rate_1', 't_narrative_1', 't_value_date_1', 't_currency_2', 't_amount_local_2', 't_amount_fcy_2', 't_rate_2', 't_narrative_2', 't_value_date_2', 't_record_status', 't_transaction_code', 'sales_person', 't_date_time', 't_account_1', 't_account_2'],
    'hashdiff_teller_other': ['t_inputter', 't_authoriser', 't_ocb_comp_rece', 't_ocb_class_rece', 't_ocb_class_amt', 't_trans_unique_id', 't_sub_va_id'],
    'hashdiff_teller_vat': ['t_contact_name', 't_tax_code', 't_vat_form', 't_vat_inv_serial', 't_vat_inv_code', 't_nat_id_type', 't_national_id', 't_nat_place_iss', 't_nat_iss_date', 't_vat_goods', 't_vat_rate', 't_vat_inv_date', 't_net_amount', 't_charge_account', 't_charge_category', 't_chrg_amt_local', 't_cust_id', 't_cheque_number'],
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
        ,is_upper=false
         )
}}
{% endif -%}
