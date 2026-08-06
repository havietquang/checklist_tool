{{ config(
    alias = 'v_stg_bpm_danh_muc_chi_tiet',
    materialized = 'view',
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = "bpm" %}
{% set source_table = "danh_muc_chi_tiet" %}
{% set business_key_cols = ['id'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = None %}
{% set list_cols = ['SUB_ID', 'PARENT_ID', 'TIEU_CHI_ID', 'GHI_CHU', 'TRANG_THAI', 'NGAY_TAO'] -%}

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
