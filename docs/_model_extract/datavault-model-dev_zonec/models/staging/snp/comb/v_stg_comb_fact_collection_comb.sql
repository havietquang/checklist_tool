{{ config(
    alias = 'v_stg_comb_fact_collection_comb',
    materialized = 'view',
    tags = ['comb', 'zonec', 'all', 'bv_zonec']
) }}

{% set source_name = "comb" %}
{% set source_table = "fact_collection_comb" %}
{% set business_key_cols = ['contract_no'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_fact_collection': ['bucket_allocation', 'app_id', 'customer_id', 'branch_code', 'currency', 'principal', 'interest', 'penalty', 'date_cob', 'created_date'],
    'hashdiff_fact_collection_dynamic': ['id'],
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
