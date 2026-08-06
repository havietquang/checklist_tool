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
    alias = 'v_stg_t24_t24_loans_and_deposits',
    materialized = 'view',
    tags = ['t24', 'crb', 'loan', 'phase2', 'phase1', 'all', 'bv_zonec']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('t24'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('t24_loans_and_deposits'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('data_date'),
                            dung de gan moc thoi gian su kien cho ban ghi.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name = 't24' -%}
{% set source_table = "t24_loans_and_deposits" -%}
{% set business_key_cols = ['id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict =
{
    'hashdiff_loans_approval': ['t_ld_aprv_date', 't_ld_aprv_level', 't_ld_aprv_user', 't_aprv_reval_user', 't_ld_aprv_ch_date', 't_aprv_ch_desc', 't_aprv_ch_level', 't_aprv_ch_user', 't_ap_rev_ch_user'],
    'hashdiff_loans_classification': ['t_category', 't_loan_subproduct', 't_loan_method', 't_loan_purpose', 't_ld_cust_group', 't_cu_cust_group', 't_ocb_prod_main', 't_ocb_pro_bundle', 't_ocb_promotion', 't_ocb_pro_partner', 't_source_of_fund', 't_ocb_outof_area', 't_industry_lev1', 't_industry_lev2', 't_industry_lev3', 't_industry_levo', 't_industry_levt', 't_liquidation_mode', 't_extend_sch', 't_vmb_class_date', 't_extendsch_date', 't_annuity_pay_method', 't_ocb_ln_hold_yn'],
    'hashdiff_loans_information': ['t_legacy_ref', 't_link_reference', 't_vmb_ln_class', 't_ln_class_manual', 't_status', 't_ocb_class_covid', 't_amount', 't_drawdown_net_amt', 't_purpose_amt', 't_amount_increase', 't_ocb_ln_hold_cif', 't_drawdown_account', 't_ocb_ln_hold_rel', 't_doubtful_sta', 't_currency', 't_linked_tfdr_ref','t_fee_pay_account','t_prin_liq_acct','t_int_liq_acct','t_limit_reference'],
    'hashdiff_loans_insurance': ['t_ins_type', 't_ins_company', 't_ins_contract', 't_ins_fee', 't_ins_start', 't_ins_end', 't_ins_amount', 't_ins_trans', 't_ins_sales_id'],
    'hashdiff_loans_other': ['t_our_remarks', 't_cust_remarks', 't_real_type', 't_auto_name', 't_auto_type', 't_ins_auto_numpla', 't_dept_code', 't_bosc_comp_ref', 't_collaborator'],
    'hashdiff_loans_rate': ['t_interest_rate', 't_interest_spread', 't_new_spread', 't_int_rate_v_date', 't_spread_v_date', 't_interest_key', 't_int_key_name', 't_int_rate_type', 't_interest_basis', 't_ocbint_chg_typ', 't_ocbint_chg_date', 't_ocb_int_supprt', 't_ocb_date_supprt', 't_tot_interest_amt', 't_min_contract_rate'],
    'hashdiff_loans_system': ['t_inputter', 't_authoriser', 't_date_time', 't_curr_no'],
    'hashdiff_loans_terms': ['t_term', 't_org_term', 't_value_date', 't_fin_mat_date', 't_amt_v_date', 't_bpm_disb_id', 't_ocb_ln_end_date', 't_orig_val_date'],
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
