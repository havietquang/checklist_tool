{{ config(
    alias = 'sat_xl_bc_thoi_gian_xu_ly_by_nhom',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['xl_ksgn_chung_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'xl_bc_thoi_gian_xu_ly_by_nhom' %}
{% set hashdiff_col = 'hashdiff_xl_bc_thoi_gian_xu_ly_by_nhom' %}
{% set hub_hashkey = 'xl_ksgn_chung_hashkey' %}
{% set source_model = 'v_stg_bpm_xl_bc_thoi_gian_xu_ly_by_nhom' %}
{% set list_cols = [
    'tong_tg_xl_gd',
    'nhom_101',
    'nhom_104',
    'nhom_105',
    'nhom_107',
    'nhom_108',
    'nhom_109',
    'nhom_111',
    'nhom_112',
    'nhom_113',
    'nhom_114',
    'nhom_116',
    'nhom_117',
    'nhom_118',
    'nhom_120',
    'nhom_121',
    'nhom_122',
    'nhom_123',
    'nhom_146',
    'nhom_147',
    'nhom_148',
    'nhom_149',
    'nhom_150',
    'nhom_151',
    'nhom_152',
    'nhom_153',
    'nhom_154',
    'nhom_155',
    'nhom_156',
    'nhom_157',
    'nhom_158',
    'nhom_164',
    'nhom_168',
    'ls_id_cuoi'
] %}
{% set raw_sql = None %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
