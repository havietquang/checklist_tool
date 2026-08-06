{{ config(
    alias = 'sat_giao_dich_tdcn_chi_tiet_san_pham',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tdcn_chi_tiet_san_pham' %}
{% set hashdiff_col = 'hashdiff_giao_dich_tdcn_chi_tiet_san_pham' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set source_model = 'v_stg_bpm_tdcn_chi_tiet_san_pham' %}
{% set list_cols = [
    'ma_key',
    'san_pham_id',
    'loai_san_pham',
    'dong_xe',
    'loai_xe',
    'gia_tri_ts',
    'fast_lane',
    'gd_tsbd',
    'trang_thai_gd_tsbd'
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
