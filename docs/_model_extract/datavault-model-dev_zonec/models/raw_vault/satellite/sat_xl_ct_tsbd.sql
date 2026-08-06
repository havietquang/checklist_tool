{{ config(
    alias = 'sat_xl_ct_tsbd',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['xl_ksgn_chung_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'xl_ct_tsbd' %}
{% set hashdiff_col = 'hashdiff_xl_ct_tsbd' %}
{% set hub_hashkey = 'xl_ksgn_chung_hashkey' %}
{% set source_model = 'v_stg_bpm_xl_ct_tsbd' %}
{% set list_cols = [
    'xl_tsbd_id',
    'loai_tsbd',
    'so_luong_tsbd',
    'ngay_tao',
    'nguoi_tao',
    'ben_ngoai_bpm',
    'gd_chinh_id'
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
