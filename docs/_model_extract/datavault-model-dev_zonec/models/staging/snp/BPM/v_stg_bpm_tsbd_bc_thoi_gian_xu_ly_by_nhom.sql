{{ config(
    alias = 'v_stg_bpm_tsbd_bc_thoi_gian_xu_ly_by_nhom',
    materialized = 'view',
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = "bpm" %}
{% set source_table = "tsbd_bc_thoi_gian_xu_ly_by_nhom" %}
{% set business_key_cols = ['ma_giao_dich'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_tsbd_bc_thoi_gian_xu_ly_by_nhom': ['gd_tsbd_id', 'tong_tg_xl_gd', 'nhom_7', 'nhom_112', 'nhom_118', 'nhom_124', 'nhom_125', 'nhom_129', 'nhom_135', 'nhom_138', 'nhom_139', 'nhom_140', 'nhom_141', 'nhom_142', 'nhom_143', 'nhom_144', 'nhom_145', 'nhom_167', 'nhom_257', 'nhom_258', 'nhom_409', 'nhom_410', 'thoi_gian_cbdg_lap_bbdg', 'thoi_diem_pc_cb_pql', 'ls_id_cuoi', 'nhom_649'],
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
