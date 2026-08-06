{{ config(
    alias = 'v_stg_bpm_y_kien_ycbs',
    materialized = 'view',
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = "bpm" %}
{% set source_table = "y_kien_ycbs" %}
{% set business_key_cols = ['id'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_y_kien_ycbs': ['quy_trinh', 'ma_giao_dich', 'user_name', 'role_name', 'ngay_tao', 'ly_do_tra_ve', 'chi_tiet_ly_do_tra_ve', 'noi_dung_chi_tiet', 'process_id', 'next_user_name', 'next_role_name', 'da_xu_ly'],
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
