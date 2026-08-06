{{ config(
    alias = 'sat_giao_dich_tdcn_nguoi_dong_vay',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tdcn_nguoi_dong_vay' %}
{% set hashdiff_col = 'hashdiff_giao_dich_tdcn_nguoi_dong_vay' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set source_model = 'v_stg_bpm_tdcn_nguoi_dong_vay' %}
{% set list_cols = [
    'ma_key',
    'parent_id',
    'sub_id',
    'ngay_sinh',
    'khach_hang_no',
    'so_cif',
    'quan_he_id',
    'quoc_tich',
    'thoi_gian_con_o_vn',
    'so_tuoi',
    'ngay_tao'
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
