{{ config(
    alias = 'v_stg_bpm_external_transaction',
    materialized = 'view',
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = "bpm" %}
{% set source_table = "external_transaction" %}
{% set business_key_cols = ['id'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_external_transaction_information': ['refcode', 'ma_giao_dich', 'ngay_tao', 'source', 'process_id', 'process_type', 'ho_ten', 'so_cif', 'ngay_sinh', 'so_dien_thoai', 'email', 'san_pham_id', 'loai_san_pham', 'so_tien_vay_dx', 'thoi_han_vay'],
    'hashdiff_external_transaction_detail': ['lso_username', 'pre_approveal_result', 'cmnd', 'ngay_cap', 'noi_cap', 'ho_chieu', 'cccd', 'gioi_tinh', 'thuong_tru', 'noi_o_hien_tai', 'tinh_trang_hon_nhan_id', 'tinh_thanh_pho_hien_tai', 'khu_vuc_khach_hang', 'tong_nhu_cau_von', 'phan_nhom_khsp', 'phuong_thuc_cho_vay', 'ltv', 'lai_suat_du_kien', 'du_no_hien_tai_cua_sp', 'dong_vay_cic', 'thoi_gian_an_han', 'fastlane', 'tong_thu_nhap_tra_no', 'nghia_vu_tra_no_thang_dau', 'nghia_vu_tra_no_thang_cao_nhat', 'nghia_vu_tra_no_hien_tai_ocb', 'nghia_vu_tra_no_hien_tai_khac', 'dti', 'ngoai_le_nguon_thu', 'ngoai_le', 'list_lich_su_tin_dung', 'list_tai_san_bao_dam', 'thong_tin_dinh_gia', 'danh_sach_nguon_thu'],
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
