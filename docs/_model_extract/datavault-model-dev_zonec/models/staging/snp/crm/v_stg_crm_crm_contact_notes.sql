{{ config(
    alias = 'v_stg_crm_crm_contact_notes',
    materialized = 'view',
    tags = ['crm', 'callcenter', 'contact', 'phase2', 'all']
) }}

{% set source_name = "crm" -%}
{% set source_table = "crm_contact_notes" -%}
{% set business_key_cols = ['ID'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict = {
    'hashdiff_contact_notes_information': ['NAME','STATUS','DATE_CREATED','USER_CREATED','DATE_UPDATED','USER_UPDATED','IS_IMPORTED','PROGRAM_TYPE','PROGRAM_CODE','IS_PROGRAM_HOT','END_DATE_PROGRAM','START_DATE_PROGRAM','ID_PRODUCT','CUSTGROUP','DEPARTMENT','PARENT_KEY','FILE_BANNER','FILE_MANUAL','FILE_INFO_PROD','DATA_TYPE','POSITION']
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
