{{ config(
    alias = 'sat_tdcn_st_van_kien',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['tdcn_st_van_kien_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tdcn_st_van_kien' %}
{% set hashdiff_col = 'hashdiff_tdcn_st_van_kien' %}
{% set hub_hashkey = 'tdcn_st_van_kien_hashkey' %}
{% set source_model = 'v_stg_bpm_tdcn_st_van_kien' %}
{% set list_cols = [
    'gd_id',
    'loai_van_kien',
    'van_kien_chi_tiet',
    'so_luong',
    'ghi_chu',
    'ngay_tao',
    'soan_thao_hs'
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
