{{ config(
    alias = 'sat_xl_bao_cao_tong_hop_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['xl_ksgn_chung_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'xl_bao_cao_tong_hop' %}
{% set hashdiff_col = 'hashdiff_xl_bao_cao_tong_hop_information' %}
{% set hub_hashkey = 'xl_ksgn_chung_hashkey' %}
{% set source_model = 'v_stg_bpm_xl_bao_cao_tong_hop' %}
{% set list_cols = [
    'gd_chinh_id',
    'ma_gd_goc',
    'trang_thai',
    'ten_khach_hang',
    'so_cif',
    'so_dkkd_cmnd',
    'loai_khach_hang',
    'dvkd_khoi_tao',
    'khoi_kd',
    'loai_quy_trinh',
    'loai_giao_dich',
    'hinh_thuc_cap_td',
    'loai_san_pham',
    'loai_tsbd',
    'so_luong_tsbd',
    'tong_rrtd_100_tien_gui',
    'tong_rrtd_khac100_tien_gui',
    'so_tien_giao_dich',
    'so_lan_trinh_pdnl',
    'don_vi_thuc_hien',
    'user_khoi_tao',
    'thoi_gian_khoi_tao',
    'rm_cuoi_cung',
    'dvtd_cuoi_cung'
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
