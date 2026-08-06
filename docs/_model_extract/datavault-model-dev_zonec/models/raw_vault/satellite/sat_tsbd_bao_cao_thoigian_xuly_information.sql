{{ config(
    alias = 'sat_tsbd_bao_cao_thoigian_xuly_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['tsbd_bao_cao_thoigian_xuly_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tsbd_bao_cao_thoigian_xuly' %}
{% set hashdiff_col = 'hashdiff_tsbd_bao_cao_thoigian_xuly_information' %}
{% set hub_hashkey = 'tsbd_bao_cao_thoigian_xuly_hashkey' %}
{% set source_model = 'v_stg_bpm_tsbd_bao_cao_thoigian_xuly' %}
{% set list_cols = [
    'gd_tsbd_id',
    'ma_giao_dich',
    'ma_loai_dvdg',
    'ten_dvdg',
    'trang_thai_gd',
    'thoi_diem_rm_hoan_thanh',
    'time_de_xuat_huy_giao_dich',
    'time_huy_giao_dich',
    'so_lan_cap_nhat',
    'ngay_cap_nhat',
    'so_lan_tdv_ycbs',
    'dvdg_ben3_de_xuat',
    'dvdg_ben3_duoc_chon',
    'cbqltsbd',
    'tbpqltsbd',
    'cbktkqdg',
    'tbpktkqdg',
    'cbqlts_received_task'
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
