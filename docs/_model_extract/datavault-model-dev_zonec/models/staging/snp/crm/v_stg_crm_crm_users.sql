{{ config(
    alias = 'v_stg_crm_crm_users',
    materialized = 'view',
    tags = ['crm', 'contact', 'phase2', 'all', 'zonec']
) }}

{% set source_name = "crm" -%}
{% set source_table = "crm_users" -%}
{% set business_key_cols = ['user_id'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict = {
    'hashdiff_crm_users_information': ['user_last_name','user_first_name','user_full_name','user_status_id','date_last_off','session_id','user_email','extension','language','user_phone','omni','telext','branch_code','custgroup','func_group','account_officer_id','job_key','nearly_job_title'],
    'hashdiff_crm_users_other': ['is_team_manage','isactive','isdeleted','is_enable_market_place','is_lso_sk','is_out_of_line','old_custgroup','old_branch_code','old_user_full_name','old_account_officer_id','old_func_group','old_user_phone','old_telext','user_created','date_created','user_updated','date_updated','user_deleted','date_deleted']
} -%}

{% if execute -%}
{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=hashdiff_satellite_dict,
    source_event_date_col=source_event_date_col,
    source_name=source_name
) }}
{% endif -%}
