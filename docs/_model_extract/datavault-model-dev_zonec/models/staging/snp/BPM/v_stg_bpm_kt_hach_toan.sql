{{ config(
    alias = 'v_stg_bpm_kt_hach_toan',
    materialized = 'view',
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = "bpm" %}
{% set source_table = "kt_hach_toan" %}
{% set business_key_cols = ['id'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_kt_hach_toan_information': ['gd_id', 'buoc_hach_toan', 'tk_ghi_no', 'ten_tk_ghi_no', 'tk_ghi_co', 'ten_tk_ghi_co', 'so_tien_ghi_no', 'so_tien_ghi_co', 'loai_tien_ghi_no', 'loai_tien_ghi_co', 'dien_giai_but_toan', 'ma_don_vi', 'ten_don_vi', 'ma_pb', 'ten_pb', 'ma_so_thue', 'ten_kh', 'mau_hd', 'ky_hieu_hd', 'so_hd', 'ngay_hd', 'ten_hh_dv', 'thue_suat', 'loai_but_toan', 'ma_but_toan', 'ket_qua_kiem_tra', 'ngay_tao', 'nguoi_tao'],
    'hashdiff_kt_hach_toan_detail': ['is_run', 'ngay_chay_but_toan', 'ket_qua_tra_ve', 'error_code', 'loai_hoach_toan', 'loai_khai_bao', 'is_hoach_toan_gom_thue', 'ma_ngan_hang', 'ten_ngan_hang', 'ngay_cap_nhat', 'retry_count', 'nguoi_cap_nhat', 'trans_gl_id', 'cb_ke_toan', 'cb_duyet', 'ty_gia', 'danh_gia_chi_phi', 'code_insert_vatfo', 'kq_insert_vatfo', 'bpm_trans_gl_id', 'ma_but_toan_goc'],
} %}

{% if execute -%}
{{ stage(source_table=source_table
        ,business_key_cols=business_key_cols
        ,hashdiff_satellite_dict=hashdiff_satellite_dict
        ,source_event_date_col=source_event_date_col
        ,source_event_date_dttype=source_event_date_dttype
        ,source_name=source_name)
}}
{% endif -%}
