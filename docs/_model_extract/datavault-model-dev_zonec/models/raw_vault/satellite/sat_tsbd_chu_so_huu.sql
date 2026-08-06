{{ config(
    alias = 'sat_tsbd_chu_so_huu',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['tsbd_chu_so_huu_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tsbd_chu_so_huu' %}
{% set hashdiff_col = 'hashdiff_tsbd_chu_so_huu' %}
{% set hub_hashkey = 'tsbd_chu_so_huu_hashkey' %}
{% set source_model = 'v_stg_bpm_tsbd_chu_so_huu' %}
{% set list_cols = [
    'ho_ten',
    'cmnd',
    'dia_chi',
    'nguoi_tao',
    'ngay_tao',
    'ngay_sinh',
    'trang_thai',
    't24',
    'loai_chu_so_huu',
    'isho',
    'ma_chu_so_huu',
    'khach_hang_id'
] %}

{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}
