{{ config(
    alias = 'sat_giao_dich_tdcn_thu_nhap_tra_no',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tdcn_thu_nhap_tra_no' %}
{% set hashdiff_col = 'hashdiff_giao_dich_tdcn_thu_nhap_tra_no' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set source_model = 'v_stg_bpm_tdcn_thu_nhap_tra_no' %}
{% set list_cols = [
    'ma_key',
    'thu_nhap_cua',
    'chi_tiet_nguon_tn',
    'so_tien',
    'ngay_tao',
    'ngoai_le_thu_nhap_tra_no',
    'noi_dung_ngoai_le',
    'chung_tu_nguon_thu'
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
