{{ config(
    alias = 'sat_bc_auth_to_chuc_don_vi_khu_vuc',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['bc_auth_to_chuc_don_vi_khu_vuc_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'bc_auth_to_chuc_don_vi_khu_vuc' %}
{% set hashdiff_col = 'hashdiff_bc_auth_to_chuc_don_vi_khu_vuc' %}
{% set hub_hashkey = 'bc_auth_to_chuc_don_vi_khu_vuc_hashkey' %}
{% set source_model = 'v_stg_bpm_bc_auth_to_chuc_don_vi_khu_vuc' %}
{% set list_cols = [
    'ten_don_vi_cap_tren'
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
