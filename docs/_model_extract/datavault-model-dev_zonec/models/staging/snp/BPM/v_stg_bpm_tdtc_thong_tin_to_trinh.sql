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
    alias = 'v_stg_bpm_tdtc_thong_tin_to_trinh',
    materialized = 'view',
    tags = ['bpm', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('bpm'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('tdtc_thong_tin_to_trinh'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['gd_id']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('DATADATE'),
                            dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung, mo ta noi dung to trinh va
                            thong tin de xuat/phe duyet giao dich.
========================================================================
*/

{% set source_name = "bpm" -%}
{% set source_table = "tdtc_thong_tin_to_trinh" -%}
{% set business_key_cols = ['gd_id'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_giao_dich_tdtc_thong_tin_to_trinh': ['id', 'khach_hang_id', 'san_pham_id', 'hang_kh', 'quoc_tich', 'ho_khau_thuong_tru', 'noi_o_hien_tai', 'tinh_thanh_hien_tai', 'sdt', 'email', 'thu_nhap_bq_thang', 'loai_hinh_dn', 'thoi_gian_dong_thue', 'dn_nhom_no_hien_tai', 'dn_ls_no_nhom_2_tro_len', 'cn_nhom_no_hien_tai', 'cn_ls_no_can_chu_y', 'cn_ls_no_xau', 'can_doi_tra_no', 'tong_rr_hien_tai', 'so_du_no_hien_tai', 'tong_rr_dx', 'de_xuat_moi', 'thoi_han_dx_moi', 'kctd_so_tien', 'kctd_muc_dich_vay', 'kctd_thoi_han_vay', 'kctd_ls_cho_vay', 'kctd_phuong_thuc_tra_no', 'ty_le_tai_tro_toi_da', 'dk_tk_payroll', 'dti', 'ngay_tao', 'nguoi_tao', 'ten_doanh_nghiep', 'ma_so_thue_dn', 'tong_thu_nhap_bq_thang', 'xep_hang_kh', 'hinh_thuc_gn', 'do_tuoi_kh', 'so_tien_pd', 'tong_rrtd_pd', 'xep_hang_dn', 'tinh_thanh_cong_tac', 'vi_tri_cong_tac', 'tong_tn_bq_thang_bds', 'dti_khong_tsbd', 'nhp_ls_no_can_chu_y', 'nhp_ls_no_xau', 'nhp_nhom_no_hien_tai', 'rating_id', 'xhtd_id']
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
