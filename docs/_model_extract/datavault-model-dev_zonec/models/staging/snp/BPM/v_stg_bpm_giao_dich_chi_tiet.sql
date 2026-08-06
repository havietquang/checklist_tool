{{ config(
    alias = 'v_stg_bpm_giao_dich_chi_tiet',
    materialized = 'view',
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = "bpm" %}
{% set source_table = "giao_dich_chi_tiet" %}
{% set business_key_cols = ['gd_id'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_giao_dich_chi_tiet_information': ['don_vi_xu_ly', 'tham_quyen', 'cap_phe_duyet', 'nguoi_phe_duyet', 'ngay_phe_duyet', 'y_kien_phe_duyet', 'sys_date', 'loai_pdnl'],
    'hashdiff_giao_dich_chi_tiet_user': ['user_vitri_1', 'user_vitri_2', 'user_vitri_3', 'user_vitri_4', 'user_vitri_5', 'user_vitri_6', 'user_vitri_7', 'user_vitri_8', 'user_vitri_9', 'user_vitri_12', 'user_vitri_14', 'user_pd_kn'],
    'hashdiff_giao_dich_chi_tiet_y_kien': ['y_kien_vitri_1', 'y_kien_vitri_2', 'y_kien_vitri_3', 'y_kien_vitri_4', 'y_kien_vitri_5', 'y_kien_vitri_6', 'y_kien_vitri_7', 'y_kien_vitri_8', 'y_kien_vitri_9', 'y_kien_vitri_12', 'y_kien_vitri_14', 'y_kien_pd_kn'],
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
