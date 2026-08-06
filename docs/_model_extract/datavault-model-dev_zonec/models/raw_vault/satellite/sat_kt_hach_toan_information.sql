{{ config(
    alias = 'sat_kt_hach_toan_information',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['kt_hach_toan_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'kt_hach_toan' %}
{% set hashdiff_col = 'hashdiff_kt_hach_toan_information' %}
{% set hub_hashkey = 'kt_hach_toan_hashkey' %}
{% set source_model = 'v_stg_bpm_kt_hach_toan' %}
{% set list_cols = [
    'gd_id',
    'buoc_hach_toan',
    'tk_ghi_no',
    'ten_tk_ghi_no',
    'tk_ghi_co',
    'ten_tk_ghi_co',
    'so_tien_ghi_no',
    'so_tien_ghi_co',
    'loai_tien_ghi_no',
    'loai_tien_ghi_co',
    'dien_giai_but_toan',
    'ma_don_vi',
    'ten_don_vi',
    'ma_pb',
    'ten_pb',
    'ma_so_thue',
    'ten_kh',
    'mau_hd',
    'ky_hieu_hd',
    'so_hd',
    'ngay_hd',
    'ten_hh_dv',
    'thue_suat',
    'loai_but_toan',
    'ma_but_toan',
    'ket_qua_kiem_tra',
    'ngay_tao',
    'nguoi_tao'
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
