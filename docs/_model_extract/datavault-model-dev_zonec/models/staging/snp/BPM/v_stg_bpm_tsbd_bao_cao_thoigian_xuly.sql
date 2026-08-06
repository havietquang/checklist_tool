{{ config(
    alias = 'v_stg_bpm_tsbd_bao_cao_thoigian_xuly',
    materialized = 'view',
    tags = ['bpm', 'zonec', 'all']
) }}

{% set source_name = "bpm" %}
{% set source_table = "tsbd_bao_cao_thoigian_xuly" %}
{% set business_key_cols = ['id'] %}
{% set staging_config = get_staging_config(source_name, source_table) %}
{% set source_event_date_col = staging_config.source_event_date_col %}
{% set source_event_date_dttype = staging_config.source_event_date_dttype %}

{% set hashdiff_satellite_dict = {
    'hashdiff_tsbd_bao_cao_thoigian_xuly_information': ['gd_tsbd_id', 'ma_giao_dich', 'ma_loai_dvdg', 'ten_dvdg', 'trang_thai_gd', 'thoi_diem_rm_hoan_thanh', 'time_de_xuat_huy_giao_dich', 'time_huy_giao_dich', 'so_lan_cap_nhat', 'ngay_cap_nhat', 'so_lan_tdv_ycbs', 'dvdg_ben3_de_xuat', 'dvdg_ben3_duoc_chon', 'cbqltsbd', 'tbpqltsbd', 'cbktkqdg', 'tbpktkqdg', 'cbqlts_received_task'],
    'hashdiff_tsbd_bao_cao_thoigian_xuly_date': ['tdv_ycbs', 'rm_bosung_tdv', 'tdv_phe_duyet', 'cbkt_ycbs', 'dvkd_bs_cbkt', 'cbkt_ycbcyk', 'dvkd_bsyk_cbkt', 'cbkt_chuyen_cpdktkqdg', 'cpdktkqdg_ycbs', 'cbkt_ycbs_tu_cpd', 'dvkd_bs_cbkt_tu_tbpktkqdg', 'cbkt_bs_tbpktkqdg', 'tbp_ktkqdg_phe_duyet', 'admin_phan_cong_cbqlts', 'time_thamdinh_tructiep', 'cbqlts_ycbs_lan1', 'rm_bs_cbqlts_lan1', 'cbqlts_ycbs_lan2', 'rm_bs_cbqlts_lan2', 'cbqltsbd_chuyen_tbpqltsbd', 'tbpqltsbd_ycbs', 'cbqlts_ycbs_tu_tbpqltsbd', 'rm_bs_cbqlts_tu_tbpqltsbd', 'cbqltsbd_bs_tbpqltsbd', 'tbpqltsbd_phe_duyet', 'tdv_ycbs_ben3', 'rm_bs_tdv_ben3', 'tdv_phe_duyet_ben3', 'pqltsbd_tra_kq_ben3_lan1', 'rm_yc_chon_lai_ben3_lan1', 'pqltsbd_tra_kq_ben3_lan2', 'rm_yc_chon_lai_ben3_lan2', 'pqltsbd_tra_kq_ben3_lan3', 'rm_hoan_thanh_ben3', 'thoi_gian_task_hang_doi', 'time_ht_thamdinh_tructiep', 'time_pc_cbbg', 'time_cbbg_ycbs', 'time_rm_bs_cbbg', 'time_cbbg_hoan_thanh', 'time_cpdbg_ycbs', 'time_rm_bs_cbbg_cks', 'time_cbbg_bs_cks', 'time_cks_hoan_thanh', 'time_cbbg_ycbs_theo_cks'],
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
