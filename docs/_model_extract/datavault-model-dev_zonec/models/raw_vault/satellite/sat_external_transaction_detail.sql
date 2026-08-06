{{ config(
    alias = 'sat_external_transaction_detail',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['external_transaction_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'external_transaction' %}
{% set hashdiff_col = 'hashdiff_external_transaction_detail' %}
{% set hub_hashkey = 'external_transaction_hashkey' %}
{% set source_model = 'v_stg_bpm_external_transaction' %}
{% set list_cols = [
    'lso_username',
    'pre_approveal_result',
    'cmnd',
    'ngay_cap',
    'noi_cap',
    'ho_chieu',
    'cccd',
    'gioi_tinh',
    'thuong_tru',
    'noi_o_hien_tai',
    'tinh_trang_hon_nhan_id',
    'tinh_thanh_pho_hien_tai',
    'khu_vuc_khach_hang',
    'tong_nhu_cau_von',
    'phan_nhom_khsp',
    'phuong_thuc_cho_vay',
    'ltv',
    'lai_suat_du_kien',
    'du_no_hien_tai_cua_sp',
    'dong_vay_cic',
    'thoi_gian_an_han',
    'fastlane',
    'tong_thu_nhap_tra_no',
    'nghia_vu_tra_no_thang_dau',
    'nghia_vu_tra_no_thang_cao_nhat',
    'nghia_vu_tra_no_hien_tai_ocb',
    'nghia_vu_tra_no_hien_tai_khac',
    'dti',
    'ngoai_le_nguon_thu',
    'ngoai_le',
    'list_lich_su_tin_dung',
    'list_tai_san_bao_dam',
    'thong_tin_dinh_gia',
    'danh_sach_nguon_thu'
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
