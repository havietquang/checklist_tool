{{ config(
    alias = 'v_stg_qldt_ldm_partner_type',
    materialized = 'view',
    tags = ['qldt', 'zonec', 'all']
) }}

{% set source_name = "qldt" %}
{% set source_table = "ldm_partner_type" %}
{% set business_key_cols = ['partner_type_id'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = None %}
{% set list_cols = ['url'] -%}

{% if execute -%}
{{ stage(source_table=source_table
        ,business_key_cols=business_key_cols
        ,hashdiff_satellite_dict=hashdiff_satellite_dict
        ,source_event_date_col=source_event_date_col
        ,source_event_date_dttype=source_event_date_dttype
        ,source_name=source_name
        ,list_cols=list_cols)
}}
{% endif -%}
