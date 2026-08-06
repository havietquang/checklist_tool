{{ config(
    alias = 'v_stg_way4_ows_evnt_action',
    materialized = 'view',
    tags = ['way4', 'reference', 'phase2', 'all']
) }}

{% set source_name = "way4" -%}
{% set source_table = "ows_evnt_action" -%}
{% set business_key_cols = ['id', 'action_code'] -%}
{% set list_cols = ['id', 'usage_action__oid', 'action_code', 'new_id', 'old_id', 'status', 'event_details'] -%}
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
