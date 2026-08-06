{{ config(
    alias = 'sat_tsbd_bc_thoi_gian_xu_ly_by_nhom',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['tsbd_giaodich_chinh_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tsbd_bc_thoi_gian_xu_ly_by_nhom' %}
{% set hashdiff_col = 'hashdiff_tsbd_bc_thoi_gian_xu_ly_by_nhom' %}
{% set hub_hashkey = 'tsbd_giaodich_chinh_hashkey' %}
{% set source_model = 'v_stg_bpm_tsbd_bc_thoi_gian_xu_ly_by_nhom' %}
{% set list_cols = [
    'gd_tsbd_id',
    'tong_tg_xl_gd',
    'nhom_7',
    'nhom_112',
    'nhom_118',
    'nhom_124',
    'nhom_125',
    'nhom_129',
    'nhom_135',
    'nhom_138',
    'nhom_139',
    'nhom_140',
    'nhom_141',
    'nhom_142',
    'nhom_143',
    'nhom_144',
    'nhom_145',
    'nhom_167',
    'nhom_257',
    'nhom_258',
    'nhom_409',
    'nhom_410',
    'thoi_gian_cbdg_lap_bbdg',
    'thoi_diem_pc_cb_pql',
    'ls_id_cuoi',
    'nhom_649'
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
