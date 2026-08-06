{{ config(
    alias = 'sat_pdtd_comment',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['pdtd_nhom_giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'pdtd_comment' %}
{% set hashdiff_col = 'hashdiff_pdtd_comment' %}
{% set hub_hashkey = 'pdtd_nhom_giao_dich_hashkey' %}
{% set source_model = 'v_stg_bpm_pdtd_comment' %}
{% set list_cols = [
    'ma_key',
    'giao_dich_id',
    'ma_giao_dich',
    'nguoi_comment_id',
    'ngay_comment',
    'noi_dung1',
    'parent_comment_id',
    'nguoi_comment_uname',
    'noi_dung2',
    'noi_dung3',
    'noi_dung4',
    'noi_dung5',
    'noi_dung6',
    'noi_dung7',
    'noi_dung8',
    'noi_dung9',
    'noi_dung10',
    'noi_dung_tom_tat',
    'vai_tro'
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
