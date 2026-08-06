{{ config(
    alias = 'sat_giao_dich_tdcn_sp_nhu_cau_td',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tdcn_sp_nhu_cau_td' %}
{% set hashdiff_col = 'hashdiff_giao_dich_tdcn_sp_nhu_cau_td' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set source_model = 'v_stg_bpm_tdcn_sp_nhu_cau_td' %}
{% set list_cols = [
    'ma_key',
    'san_pham_id',
    'loai_san_pham',
    'phan_nhom_kh_theo_sp',
    'phuong_thuc_cho_vay',
    'ty_le_vay',
    'tong_nhu_cau_von',
    'so_tien_vay_dx',
    'thoi_gian_vay',
    'lai_suat_vay_du_kien',
    'du_no_hien_tai_sp',
    'rrtd_co_tsbd',
    'rrtd_khong_co_tsbd',
    'rrtd_tat_ca_sp',
    'rrtd_tat_ca_sp_khong_tsbd',
    'rrtd_sp_thong_thuong',
    'rrtd_sp_thong_thuong_khong_tsbd',
    'ngay_tao',
    'dong_vay_co_cic',
    'so_tien_pd',
    'rrtd_co_tsbd_pd',
    'rrtd_khong_co_tsbd_pd',
    'rrtd_tat_ca_sp_pd',
    'rrtd_tat_ca_sp_khong_tsbd_pd',
    'rrtd_sp_thong_thuong_pd',
    'rrtd_sp_thong_thuong_khong_tsbd_pd',
    'tong_rrtd_st',
    'tong_rrtd_xl',
    'dieu_kien_bu_dap',
    'nguoi_so_ts_tu_von_vay',
    'rrtd_doi_voi_kh_ocb',
    'muc_dich_vay',
    'rrtd_doi_voi_kh_ocb_pd',
    'rrtd_trinhcaptd_lan_nay',
    'rrtd_trinhcaptd_lan_nay_pd',
    'thoi_gian_an_han',
    'mua_ban_uy_quyen',
    'rrtd_tat_ca_sp_khong_tsbd_temp',
    'khu_vuc_khach_hang',
    'phuong_phap_cm_thu_nhap',
    'khoan_vay_theo_cs_cbnv',
    'muc_dich',
    'phuong_phap_cmtn',
    'khoan_vay_cs_cbnv'
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
