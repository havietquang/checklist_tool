{{ config(
    alias = 'v_stg_comb_consumer_loan_wo',
    materialized = 'view',
    tags = ['comb', 'zonec', 'all', 'bv_zonec']
) }}

{% set source_name = "comb" %}
{% set source_table = "consumer_loan_wo" %}
{% set business_key_cols = ['contract_no'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_consumer_loan_wo': ['app_id', 'customer_id', 'branch_code', 'currency', 'mature_date', 'open_date', 'disbursment_amount', 'oustanding_amount', 'custgroup', 'loan_classification', 'begin_repayment_date', 'next_repayment_date', 'frequency', 'interst_amount', 'pd_interest', 'interest_rate', 'interest_type', 'industry_level_3', 'term', 'purpose_id', 'extend_sch', 'extendsch_date', 'account_officer_id', 'product_id', 'provision_amount', 'provision_oustanding', 'link_reference', 'full_name', 'legal_id', 'gl', 'pd_amount_eq', 'pr_day', 'in_day', 'interest_rate1', 'interest_spread', 'sbv21_sector_legal', 'loan_subproduct', 'datasource', 'loan_subproduct_name', 'purpose_name', 'on_due_principal', 'acrrual_balance'],
    'hashdiff_consumer_loan_wo_dynamic': ['id'],
} %}

{% if execute -%}
{{ stage(source_table=source_table
        ,business_key_cols=business_key_cols
        ,hashdiff_satellite_dict=hashdiff_satellite_dict
        ,source_event_date_col=source_event_date_col
        ,source_event_date_dttype=source_event_date_dttype
        ,source_name=source_name)
}}
{% endif -%}
