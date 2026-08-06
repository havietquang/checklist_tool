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
    alias = 'v_stg_t24_t24_collateral',
    materialized = 'view',
    tags = ['t24', 'collateral', 'phase2', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_collateral'),
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
{% set source_table = "t24_collateral" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_collateral_information': ['t_collateral_type', 't_description', 't_collateral_code', 't_coll_status', 't_expiry_date', 't_value_date', 't_ocb_co_note', 't_notes', 't_in_cluster', 't_borrow_purpose', 't_ld_cust_group', 't_ocb_start_date', 't_ocb_end_date', 't_inputter', 't_date_time', 't_authoriser','T_CURRENCY', 't_application_id'],
    'hashdiff_collateral_instrument': ['t_coll_sec_id', 't_coll_sec_number', 't_appoint_date', 't_ocb_bonds_id', 't_ocb_listing', 't_ocb_inter_rate', 't_ocb_pay_me_rate', 't_ocb_listed', 't_ocb_ward_2', 't_ocb_quantity', 't_ocb_credit_orga', 't_imp_store_id', 't_ocb_gtcg_issuer', 't_ocb_issuer', 't_ocb_series'],
    'hashdiff_collateral_insurance': ['t_ins_contract', 't_coll_ins_status', 't_coll_ins_prod', 't_coll_ins_comp', 't_ins_amount', 't_ins_fee', 't_ins_start', 't_ins_end'],
    'hashdiff_collateral_other': ['t_ocb_coll_store', 't_contract_link'],
    'hashdiff_collateral_real_estate': ['t_houseprj_cb', 't_ocb_project_nam', 't_ocb_project_inv', 't_ocb_tot_vl_inve', 't_ocb_pr_end_date', 't_ocb_rec_est_dat', 't_ocb_lea_est_dat', 't_ocb_issuer', 't_ocb_parcel_num', 't_ocb_map_num', 't_country', 't_province_2', 't_town_country_2', 't_ward_2', 't_add_num', 't_address'],
    'hashdiff_collateral_valuation': ['t_nominal_value', 't_execution_value', 't_gen_ledger_value', 't_central_bank_value', 't_coll_price', 't_coll_number', 't_maximum_value', 't_loan_ratio', 't_ocb_val_date', 't_ocb_val_agent', 't_ocb_reval_date', 't_ocb_reval_agent', 't_ocb_reval_amt', 't_reval_next_date', 't_ocb_pric_date', 't_ocb_pric_organ', 't_ocb_next_date', 't_ocb_is_revalu', 't_ocb_coll_rls', 't_ocb_pric_val_rl', 't_ocb_pric_dat_rl', 't_ocb_pric_or_rls'],
    'hashdiff_collateral_vehicle': ['t_ocb_estate_num', 't_ocb_fram_num', 't_ocb_estate_reg', 't_ocb_coll_type', 't_ocb_trade_mark', 't_ocb_pr_licen_no', 't_ocb_series'],
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
