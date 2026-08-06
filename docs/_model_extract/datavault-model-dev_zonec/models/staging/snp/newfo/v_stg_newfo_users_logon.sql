{{ config(
    alias = 'v_stg_newfo_users_logon',
    materialized = 'view',
    tags = ['newfo', 'zonec', 'all']
) }}

{% set source_name = "newfo" %}
{% set source_table = "users_logon" %}
{% set business_key_cols = ['user_id'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_users_logon': ['user_last_name', 'user_first_name', 'branch_code', 'user_status', 'user_t24', 'till_no', 'user_created', 'date_created', 'user_session'],
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
