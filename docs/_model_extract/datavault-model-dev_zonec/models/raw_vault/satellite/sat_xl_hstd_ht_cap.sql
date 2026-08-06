{{ config(
    alias = 'sat_xl_hstd_ht_cap',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['xl_ksgn_chung_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'xl_hstd_ht_cap' %}
{% set hashdiff_col = 'hashdiff_xl_hstd_ht_cap' %}
{% set hub_hashkey = 'xl_ksgn_chung_hashkey' %}
{% set source_model = 'v_stg_bpm_xl_hstd_ht_cap' %}
{% set list_cols = [
    'hthuc_cap_id',
    'loai_van_kien',
    'van_kien_ct',
    'ngay_tao',
    'nguoi_tao',
    'ghi_chu',
    'don_vi_xu_ly',
    'ben_ngoai_bpm',
    'so_luong',
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
