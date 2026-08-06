{{ config(
    alias = 'sat_md_3544_san_pham_t24',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['md_3544_san_pham_t24_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'md_3544_san_pham_t24' %}
{% set hashdiff_col = 'hashdiff_md_3544_san_pham_t24' %}
{% set hub_hashkey = 'md_3544_san_pham_t24_hashkey' %}
{% set source_model = 'v_stg_bpm_md_3544_san_pham_t24' %}
{% set list_cols = [
    'ma_san_pham',
    'ten_san_pham',
    'phan_nhom_san_pham_t24',
    'parent_group'
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
