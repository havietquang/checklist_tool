{{ config(
    alias = 'v_stg_way4_ows_bin_table',
    materialized = 'view',
    tags = ['way4', 'reference', 'phase2', 'all']
) }}

{% set source_name = "way4" -%}
{% set source_table = "ows_bin_table" -%}
{% set business_key_cols = ['id'] -%}
{% set list_cols = ['amnd_state', 'amnd_date', 'amnd_officer', 'amnd_prev', 'id', 'bin_group__oid', 'name', 'member_id', 'start_bin', 'end_bin', 'start_bin_4', 'pan_length', 'bin_condition', 'bin_details', 'card_brand', 'card_org', 'card_technology', 'cdv_algorithm', 'channel', 'country', 'data_source', 'ec_atm_type', 'forwarding_id', 'ica_number', 'processing_class', 'product_id', 'licensed_product_id', 'product_category', 'region_for_issuer', 'service_indicator', 'terminal_category', 'usage', 'usage_domain', 'bin_status'] -%}
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
