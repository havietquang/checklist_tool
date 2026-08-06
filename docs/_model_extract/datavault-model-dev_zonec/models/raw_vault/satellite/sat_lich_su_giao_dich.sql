{{ config(
    alias = 'sat_lich_su_giao_dich',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'lich_su_giao_dich' %}
{% set hashdiff_col = 'hashdiff_lich_su_giao_dich' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set source_model = 'v_stg_bpm_lich_su_giao_dich' %}
{% set list_cols = [
    'ma_key',
    'vai_tro_nguoi_xl',
    'vai_tro_tiep_theo',
    'vai_tro_truoc',
    'thoi_diem_bat_dau',
    'thoi_diem_ket_thuc',
    'ten_tac_vu',
    'trang_thai_ban_dau',
    'trang_thai_ket_thuc',
    'luong_id',
    'ket_qua_xu_ly',
    'task_id',
    'nguoi_tao_id',
    'ngay_tao',
    'ngay_cap_nhat',
    'chuc_danh',
    'thoi_gian_xu_ly',
    'don_vi_id'
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
