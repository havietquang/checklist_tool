{{ config(
    alias = 'v_stg_comb_app_product',
    materialized = 'view',
    tags = ['comb', 'zonec', 'all']
) }}

{% set source_name = "comb" %}
{% set source_table = "app_product" %}
{% set business_key_cols = ['productcode'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_app_product': ['producttype', 'productname', 'status', 'minloanamount', 'maxloanamount', 'interestrate', 'mintenor', 'maxtenor', 'validfrom', 'validto', 'changeddate'],
    'hashdiff_app_product_dynamic': ['id'],
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
