{{ config(
    alias = 'sat_giao_dich_chi_tiet_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'giao_dich_chi_tiet' %}
{% set hashdiff_col = 'hashdiff_giao_dich_chi_tiet_information' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set source_model = 'v_stg_bpm_giao_dich_chi_tiet' %}
{% set list_cols = [
    'don_vi_xu_ly',
    'tham_quyen',
    'cap_phe_duyet',
    'nguoi_phe_duyet',
    'ngay_phe_duyet',
    'y_kien_phe_duyet',
    'sys_date',
    'loai_pdnl'
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
