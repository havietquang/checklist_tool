{{ config(
    alias = 'sat_auth_to_chuc_dvi_link',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['auth_to_chuc_dvi_link_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'auth_to_chuc_dvi_link' %}
{% set hashdiff_col = 'hashdiff_auth_to_chuc_dvi_link' %}
{% set hub_hashkey = 'auth_to_chuc_dvi_link_hashkey' %}
{% set source_model = 'v_stg_bpm_auth_to_chuc_dvi_link' %}
{% set list_cols = [
    'don_vi_goc_id',
    'don_vi_lket_id'
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
