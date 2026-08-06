{{ config(
    alias = 'sat_kt_hach_toan_detail',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['kt_hach_toan_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'kt_hach_toan' %}
{% set hashdiff_col = 'hashdiff_kt_hach_toan_detail' %}
{% set hub_hashkey = 'kt_hach_toan_hashkey' %}
{% set source_model = 'v_stg_bpm_kt_hach_toan' %}
{% set list_cols = [
    'is_run',
    'ngay_chay_but_toan',
    'ket_qua_tra_ve',
    'error_code',
    'loai_hoach_toan',
    'loai_khai_bao',
    'is_hoach_toan_gom_thue',
    'ma_ngan_hang',
    'ten_ngan_hang',
    'ngay_cap_nhat',
    'retry_count',
    'nguoi_cap_nhat',
    'trans_gl_id',
    'cb_ke_toan',
    'cb_duyet',
    'ty_gia',
    'danh_gia_chi_phi',
    'code_insert_vatfo',
    'kq_insert_vatfo',
    'bpm_trans_gl_id',
    'ma_but_toan_goc'
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
