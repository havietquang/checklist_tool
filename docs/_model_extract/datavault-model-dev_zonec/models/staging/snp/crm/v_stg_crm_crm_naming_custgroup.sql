{{ config(
    alias = 'v_stg_crm_crm_naming_custgroup',
    materialized = 'view',
    tags = ['crm', 'reference', 'phase2', 'all']
) }}

{% set source_name = "crm" -%}
{% set source_table = "crm_naming_custgroup" -%}
{% set business_key_cols = ['custgroup'] -%}
{% set list_cols = ['custgroup', 'name', 'user_created', 'date_created', 'user_updated', 'date_updated', 'user_deleted', 'date_deleted', 'isactive', 'isdeleted', 'parent_key'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict = none -%}

{% if execute -%}
{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=hashdiff_satellite_dict,
    source_event_date_col=source_event_date_col,
    source_name=source_name
        ,list_cols=list_cols
        ) }}
{% endif -%}
