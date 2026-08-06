{{ config(
    alias = 'v_stg_t24_t24_aa_arrangement',
    materialized = 'view',
    tags = ['t24', 'zonec', 'all']
) }}

{% set source_name = "t24" %}
{% set source_table = "t24_aa_arrangement" %}
{% set business_key_cols = ['id'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_aa_arrangement_information': ['t_currency', 't_co_code', 't_start_date', 't_product_line', 't_product_group', 't_product', 't_linked_appl', 't_linked_appl_id', 't_customer_role', 't_arr_status'],
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
