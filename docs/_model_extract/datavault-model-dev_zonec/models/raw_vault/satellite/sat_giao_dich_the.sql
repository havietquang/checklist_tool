{{ config(
    alias = 'sat_giao_dich_the',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'giao_dich_the' %}
{% set hashdiff_col = 'hashdiff_giao_dich_the' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set source_model = 'v_stg_bpm_giao_dich_the' %}
{% set list_cols = [
    'ma_key',
    'kh_id',
    'so_the',
    'loai_the',
    'loai_the_t24',
    'loai_the_chi_tiet',
    'ten_in_tren_the',
    'han_muc_de_xuat',
    'han_muc_phe_duyet',
    'dia_chi',
    'the_chinh_phu',
    'tinh_trang_the',
    'so_tk_the',
    'tinh_trang_tk_the',
    'the_pre_approved',
    'nhom_cskh',
    'hieu_luc_the',
    'branch_code',
    'phat_hanh_the_phu',
    'y_kien',
    'sys_date',
    'loai_the_ttt',
    'status_code',
    'reason_message'
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
