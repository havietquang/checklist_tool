{{ config(
    alias = 'sat_giao_dich_chi_tiet_user',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'giao_dich_chi_tiet' %}
{% set hashdiff_col = 'hashdiff_giao_dich_chi_tiet_user' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set source_model = 'v_stg_bpm_giao_dich_chi_tiet' %}
{% set list_cols = [
    'user_vitri_1',
    'user_vitri_2',
    'user_vitri_3',
    'user_vitri_4',
    'user_vitri_5',
    'user_vitri_6',
    'user_vitri_7',
    'user_vitri_8',
    'user_vitri_9',
    'user_vitri_12',
    'user_vitri_14',
    'user_pd_kn'
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
