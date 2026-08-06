{{ config(
    alias = 'v_stg_bpm_tdcn_st_van_kien',
    materialized = 'view',
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = "bpm" %}
{% set source_table = "tdcn_st_van_kien" %}
{% set business_key_cols = ['id'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_tdcn_st_van_kien': ['gd_id', 'loai_van_kien', 'van_kien_chi_tiet', 'so_luong', 'ghi_chu', 'ngay_tao', 'soan_thao_hs'],
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
