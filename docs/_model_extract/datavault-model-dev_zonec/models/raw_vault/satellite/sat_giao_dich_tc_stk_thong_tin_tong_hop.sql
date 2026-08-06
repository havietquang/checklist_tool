{{ config(
    alias = 'sat_giao_dich_tc_stk_thong_tin_tong_hop',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tc_stk_thong_tin_tong_hop' %}
{% set hashdiff_col = 'hashdiff_giao_dich_tc_stk_thong_tin_tong_hop' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set source_model = 'v_stg_bpm_tc_stk_thong_tin_tong_hop' %}
{% set list_cols = [
    'ma_key',
    'ma_giao_dich',
    'ngay_kh_de_xuat',
    'ngay_pd_tk',
    'so_cif',
    'cmnd',
    'ho_ten',
    'so_tktc',
    'sdt',
    'email',
    'so_stk',
    'gia_tri_tsbd',
    'ma_tsbd',
    'ngay_bat_dau_hm',
    'ngay_ket_thuc_hm',
    'ma_han_muc',
    'so_tien_hm',
    'loai_tien',
    'ma_trang_thai',
    'trang_thai_bpm',
    'ngay_tao',
    'ngay_phe_duyet',
    'nguoi_phe_duyet',
    'ngay_xuat_file',
    'process_id',
    'cn_ql_tktc',
    'cat_tktc',
    'cn_ql_stk',
    'ls_so_stk',
    'bien_do_ls',
    'ma_lien_ket_quyen',
    'cn_ql_lien_ket_quyen',
    'tai_khoan_wa',
    'dien_giai_loi',
    'ngay_ky',
    'transaction_id'
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
