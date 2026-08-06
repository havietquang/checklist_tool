{{ config(
    alias = 'v_stg_way4_ows_branch',
    materialized = 'view',
    tags = ['way4', 'reference', 'zonec', 'all']
) }}

{% set source_name = "way4" -%}
{% set source_table = "ows_branch" -%}
{% set business_key_cols = ['id', 'code'] -%}
{% set list_cols = ['ID', 'CODE', 'AMND_STATE', 'AMND_DATE', 'AMND_OFFICER', 'AMND_PREV', 'F_I', 'BRANCH__OID', 'LIAB_CONTRACT', 'UNIT', 'BANK_CLIENT', 'TIME_ZONE', 'UNIT_TYPE'] -%}
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
