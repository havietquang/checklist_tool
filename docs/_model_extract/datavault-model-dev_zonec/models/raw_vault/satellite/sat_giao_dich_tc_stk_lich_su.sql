{{ config(
    alias = 'sat_giao_dich_tc_stk_lich_su',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tc_stk_lich_su' %}
{% set hashdiff_col = 'hashdiff_giao_dich_tc_stk_lich_su' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set source_model = 'v_stg_bpm_tc_stk_lich_su' %}
{% set list_cols = [
    'ma_key',
    'ma_giao_dich',
    'process_id',
    'trang_thai_bpm',
    'ngay_phe_duyet',
    'nguoi_phe_duyet',
    'ngay_xuat_file',
    'dien_giai_loi_bpm',
    'ngay_tao'
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
