{{ config(
    alias = 'v_stg_bpm_xl_bc_thoi_gian_xu_ly_by_nhom',
    materialized = 'view',
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = "bpm" %}
{% set source_table = "xl_bc_thoi_gian_xu_ly_by_nhom" %}
{% set business_key_cols = ['ma_giao_dich'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_xl_bc_thoi_gian_xu_ly_by_nhom': ['tong_tg_xl_gd', 'nhom_101', 'nhom_104', 'nhom_105', 'nhom_107', 'nhom_108', 'nhom_109', 'nhom_111', 'nhom_112', 'nhom_113', 'nhom_114', 'nhom_116', 'nhom_117', 'nhom_118', 'nhom_120', 'nhom_121', 'nhom_122', 'nhom_123', 'nhom_146', 'nhom_147', 'nhom_148', 'nhom_149', 'nhom_150', 'nhom_151', 'nhom_152', 'nhom_153', 'nhom_154', 'nhom_155', 'nhom_156', 'nhom_157', 'nhom_158', 'nhom_164', 'nhom_168', 'ls_id_cuoi'],
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
