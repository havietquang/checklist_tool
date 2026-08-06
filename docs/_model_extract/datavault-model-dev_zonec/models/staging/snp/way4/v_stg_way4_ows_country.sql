{{ config(
    alias = 'v_stg_way4_ows_country',
    materialized = 'view',
    tags = ['way4', 'reference', 'zonec', 'all']
) }}

{% set source_name = "way4" -%}
{% set source_table = "ows_country" -%}
{% set business_key_cols = ['id', 'code'] -%}
{% set list_cols = ['ID', 'CODE', 'AMND_DATE', 'AMND_STATE', 'AMND_OFFICER', 'AMND_PREV', 'AREA_DFLT', 'CODE_2', 'CURR_CODE', 'CURR_NAME', 'CUSTOM_CODE', 'DEFAULT_LANGUAGE', 'LIMIT_CODE', 'N_CODE', 'N_CURR_CODE', 'POSTAL_CODE', 'USE_IN_BANK', 'COUNTRY_OBJECT__ID', 'CALENDAR_TYPE'] -%}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}
{% set hashdiff_satellite_dict = None -%}

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
