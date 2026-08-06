{{ config(
    alias = 'sat_giao_dich_chi_tiet_y_kien',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'giao_dich_chi_tiet' %}
{% set hashdiff_col = 'hashdiff_giao_dich_chi_tiet_y_kien' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set source_model = 'v_stg_bpm_giao_dich_chi_tiet' %}
{% set list_cols = [
    'y_kien_vitri_1',
    'y_kien_vitri_2',
    'y_kien_vitri_3',
    'y_kien_vitri_4',
    'y_kien_vitri_5',
    'y_kien_vitri_6',
    'y_kien_vitri_7',
    'y_kien_vitri_8',
    'y_kien_vitri_9',
    'y_kien_vitri_12',
    'y_kien_vitri_14',
    'y_kien_pd_kn'
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
