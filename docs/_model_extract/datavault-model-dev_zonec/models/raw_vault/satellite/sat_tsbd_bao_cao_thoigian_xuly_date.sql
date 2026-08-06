{{ config(
    alias = 'sat_tsbd_bao_cao_thoigian_xuly_date',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['tsbd_bao_cao_thoigian_xuly_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tsbd_bao_cao_thoigian_xuly' %}
{% set hashdiff_col = 'hashdiff_tsbd_bao_cao_thoigian_xuly_date' %}
{% set hub_hashkey = 'tsbd_bao_cao_thoigian_xuly_hashkey' %}
{% set source_model = 'v_stg_bpm_tsbd_bao_cao_thoigian_xuly' %}
{% set list_cols = [
    'tdv_ycbs',
    'rm_bosung_tdv',
    'tdv_phe_duyet',
    'cbkt_ycbs',
    'dvkd_bs_cbkt',
    'cbkt_ycbcyk',
    'dvkd_bsyk_cbkt',
    'cbkt_chuyen_cpdktkqdg',
    'cpdktkqdg_ycbs',
    'cbkt_ycbs_tu_cpd',
    'dvkd_bs_cbkt_tu_tbpktkqdg',
    'cbkt_bs_tbpktkqdg',
    'tbp_ktkqdg_phe_duyet',
    'admin_phan_cong_cbqlts',
    'time_thamdinh_tructiep',
    'cbqlts_ycbs_lan1',
    'rm_bs_cbqlts_lan1',
    'cbqlts_ycbs_lan2',
    'rm_bs_cbqlts_lan2',
    'cbqltsbd_chuyen_tbpqltsbd',
    'tbpqltsbd_ycbs',
    'cbqlts_ycbs_tu_tbpqltsbd',
    'rm_bs_cbqlts_tu_tbpqltsbd',
    'cbqltsbd_bs_tbpqltsbd',
    'tbpqltsbd_phe_duyet',
    'tdv_ycbs_ben3',
    'rm_bs_tdv_ben3',
    'tdv_phe_duyet_ben3',
    'pqltsbd_tra_kq_ben3_lan1',
    'rm_yc_chon_lai_ben3_lan1',
    'pqltsbd_tra_kq_ben3_lan2',
    'rm_yc_chon_lai_ben3_lan2',
    'pqltsbd_tra_kq_ben3_lan3',
    'rm_hoan_thanh_ben3',
    'thoi_gian_task_hang_doi',
    'time_ht_thamdinh_tructiep',
    'time_pc_cbbg',
    'time_cbbg_ycbs',
    'time_rm_bs_cbbg',
    'time_cbbg_hoan_thanh',
    'time_cpdbg_ycbs',
    'time_rm_bs_cbbg_cks',
    'time_cbbg_bs_cks',
    'time_cks_hoan_thanh',
    'time_cbbg_ycbs_theo_cks'
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
