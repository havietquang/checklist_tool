/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['bpm'] = filter khi run (dbt run --select tag:bpm)
====================================================================
*/

{{ config(
    alias = 'v_stg_bpm_pdtd_nhom_giao_dich',
    materialized = 'view',
    tags = ['bpm', 'phase2', 'phase1', 'zonec', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('bpm'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('pdtd_nhom_giao_dich'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['MA_GIAO_DICH']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('DATADATE'),
                            dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach  
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name = "bpm" -%}
{% set source_table = "pdtd_nhom_giao_dich" -%}
{% set business_key_cols = ['ma_giao_dich'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_pdtd_nhom_giao_dich_trang_thai': ['trang_thai_giao_dich', 'trang_thai_phe_duyet', 'role_dang_xl', 'trang_thai_hoat_dong', 'ket_qua_thao_tac_cuoi', 'process_id', 'luong_id', 'ngay_tao', 'thoi_diem_thao_tac_cuoi', 'ngay_hoan_thanh'],
    'hashdiff_pdtd_nhom_giao_dich_ho_so': ['id','tong_so_tien', 'so_tien_pd', 'so_tien_pd_kn', 'tong_pd_muc_cap_tin_dung', 'tong_rrtd_d1', 'quy_che_blanh_khac', 'quy_dinh_tin_dung', 'csach_tin_dung_kh', 'tuan_thu_dk_pduyet', 'phe_duyet_boi_uy_ban', 'cap_td_co_du_an_dt', 'cap_td_db_100_bds_oto', 'ls_thap_hon_ls_dcv', 'mua_bao_hiem', 'ngoai_le_cam_ket_vay_co_dk', 'ksvttd', 'khoan_vay_cs_cbnv', 'is_trinh_vuot_cap_d1', 'is_thay_doi_tt', 'khach_hang_tctd', 'trinh_ho_tro_ls_theo_qd', 'kh_adgiam_tat_rb', 'noi_dung_ycgt'],
    'hashdiff_pdtd_nhom_giao_dich_han_muc': ['hmrr_dx_kh_100_tgui','hmrr_dx_kh_ko_100_tgui','hmrr_dx_kh_100_fi_tgui','hmrr_dx_kh_nlq_100_tgui','hmrr_dx_kh_nlq_ko_100_tgui','hmrr_htai_kh_100_tgui','hmrr_htai_kh_ko_100_tgui','hmrr_htai_kh_nlq_100_tgui','hmrr_htai_kh_nlq_ko_100_tgui','rrtd_kh_ko_tsbd','rrtd_kh_ko_100_tgui_tru_tp','hmrr_pd_kh_100_tgui','hmrr_pd_kh_ko_100_tgui','hmrr_sp_cu_the_covako_tsdb','hmrr_sp_cu_the_ko_tsdb','rrtd_pd_sp_cuthe_covako_tsbd','hmrr_pd_kh_dam_bao','hmrr_pd_kh_khong_dam_bao'],
    'hashdiff_pdtd_nhom_giao_dich_tham_dinh': ['loai_tien','tinh_trang_no_cic','tsbd_nhieu_kh','tsbd_thuoc_pduyet_hoi_so','spham_tdung_tsbd','ngoai_le_tsdb','kh_mien_pduyet_tt','tdiem_tdtt','nhom2_no_cic_12t','xep_hang_td','gtri_cam_ket','tong_gtri_cam_ket','trang_thai_tdtt','quy_trinh_con','khoan_cap_tin_dung','ngay_ky_hdtd','ngay_het_han_hdtd','dk_danh_gia_tiep_tuc_giai_ngan','phuong_phap_cmtn'],
    'hashdiff_pdtd_nhom_giao_dich_phe_duyet': ['nguoi_khoi_tao','nguoi_dang_xu_ly','don_vi_kdoanh','cbttd','gdpdtd','don_vi_pduyet','nguoi_phu_trach','bspo_id','cgpddl','cap_phe_duyet_cuoi_id','nhom_khach_hang','loai_nhom_giao_dich','nhom_ho_so','nhom_giao_dich_goc_id','hangkh','rating_id'
]
}
-%}


/*
------------------------------------------------------------------------
STAGE MACRO CALL
------------------------------------------------------------------------
Guard `if execute` ngan macro chay luc dbt parse/compile
(tranh loi khi chua co context thuc thi).
Macro `stage()` se sinh ra cau SELECT day du gom:
  - Tat ca cot goc tu source
  - Cot hashkey (hash cua business_key_cols)
  - Cac cot hashdiff theo hashdiff_satellite_dict
  - Cot record_source, source_event_date, load_timestamp
------------------------------------------------------------------------
*/

{% if execute -%}
{{ stage(source_table=source_table
        ,business_key_cols=business_key_cols
        ,hashdiff_satellite_dict=hashdiff_satellite_dict
        ,source_event_date_col=source_event_date_col
        ,source_event_date_dttype=source_event_date_dttype
        ,source_name = source_name)
}}
{% endif -%}
