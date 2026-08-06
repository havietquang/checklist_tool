{{ config(
    alias = 'sat_giao_dich_tcstk_thong_tin_bao_dam',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tcstk_thong_tin_bao_dam' %}
{% set hashdiff_col = 'hashdiff_giao_dich_tcstk_thong_tin_bao_dam' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set source_model = 'v_stg_bpm_tcstk_thong_tin_bao_dam' %}
{% set list_cols = [
    'ma_key',
    'ten_tsbd',
    'ma_tsbd',
    'gia_tri_tsbd',
    'tyle_bao_dam',
    'trang_thai_ts',
    'ngay_bat_dau_co_hl',
    'ngay_het_han',
    'han_muc_tc_bd',
    'hm_tc_con_lai',
    'hm_dc_da_sd',
    'ngay_tao',
    'nguoi_tao',
    'ngay_cap_nhat',
    'nguoi_cap_nhat',
    'is_delete',
    'id_ttgd',
    'giatri_baodam',
    'ngay_ms',
    'ngay_dao_han',
    'ma_hm',
    'ma_lkq',
    'trang_thai_phong_toa',
    'status',
    'loai_tien',
    'lai_suat',
    'so_so_tk',
    'ki_han',
    'ten_san_pham',
    'productcode',
    'lai_suat_tk',
    'stt_so',
    'trang_thaihm',
    'ly_do',
    'hinh_thuc_tt_stk',
    'ma_phong_toa',
    'so_tai_khoan_so',
    'madcaz',
    'is_checkstk',
    'is_tao_ts_bd',
    'is_dieu_chinh',
    'is_phong_toa',
    'ma_chi_nhanh_stk',
    'is_giai_toa_ts',
    'ma_giaitoa',
    'is_giai_chap_ts',
    'ma_giaichap',
    'is_tat_toan',
    'ma_tat_toan'
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
