{{ config(
    alias = 'sat_y_kien_ycbs',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['y_kien_ycbs_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'y_kien_ycbs' %}
{% set hashdiff_col = 'hashdiff_y_kien_ycbs' %}
{% set hub_hashkey = 'y_kien_ycbs_hashkey' %}
{% set source_model = 'v_stg_bpm_y_kien_ycbs' %}
{% set list_cols = [
    'quy_trinh',
    'ma_giao_dich',
    'user_name',
    'role_name',
    'ngay_tao',
    'ly_do_tra_ve',
    'chi_tiet_ly_do_tra_ve',
    'noi_dung_chi_tiet',
    'process_id',
    'next_user_name',
    'next_role_name',
    'da_xu_ly'
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
