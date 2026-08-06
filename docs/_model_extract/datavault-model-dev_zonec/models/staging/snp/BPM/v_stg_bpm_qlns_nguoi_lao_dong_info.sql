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
    alias = 'v_stg_bpm_qlns_nguoi_lao_dong_info',
    materialized = 'view',
    tags = ['bpm', 'phase2', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('bpm'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('qlns_nguoi_lao_dong_info'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['ma_nhan_vien']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : None = nguon khong co cot ngay su kien ro rang;
                            macro se dung ngay load thay the.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung, tach thanh cac nhom thong tin
                            ca nhan, don vi, hop dong, luong thuong va ky luat.
========================================================================
*/

{% set source_name = "bpm" -%}
{% set source_table = "qlns_nguoi_lao_dong_info" -%}
{% set business_key_cols = ['ma_nhan_vien'] -%}
{% set source_event_date_col = get_source_event_date_col(source_name, source_table, required=true) -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_qlns_nguoi_lao_dong_info_ca_nhan': ['ho_ten', 'ngay_sinh', 'gioi_tinh', 'ma_gioi_tinh', 'cmnd', 'ngay_cap_cmnd', 'noi_cap', 'so_dien_thoai', 'email_ca_nhan', 'email_co_quan', 'dia_chi_thuong_tru', 'trinh_do', 'chuyen_nganh', 'ngay_dong_bo'],
    'hashdiff_qlns_nguoi_lao_dong_info_don_vi': ['khoi', 'ma_khoi', 'don_vi', 'ma_don_vi', 'phong_ban', 'ma_phong_ban', 'bo_phan', 'ma_bo_phan', 'to_nhom', 'ma_to_nhom', 'noi_lam_viec', 'chuc_danh', 'ma_chuc_danh', 'chuc_danh_nnv', 'ma_chuc_danh_nnv', 'chuc_danh_1', 'phan_nhom_chuc_danh', 'cap_bac', 'ma_cap_bac', 'tham_nien_vi_tri', 'ten_dang_nhap'],
    'hashdiff_qlns_nguoi_lao_dong_info_hop_dong_lao_dong': ['loai_hd_hien_tai', 'ma_loai_hd', 'hdld_tu_ngay', 'hdld_den_ngay', 'so_lan_da_ky_hd', 'ma_loai_nhan_vien', 'tinh_trang_nhan_vien', 'ngay_vao_ocb', 'loai_nghi_phep', 'thoi_gian_bat_dau_nghi_phep', 'thoi_gian_ket_thuc_nghi_phep', 'so_ngay_nghi_phep', 'ly_do_nghi', 'ngay_vao_ocb_chinh_thuc', 'ngay_lam_viec_cuoi_cung', 'ngay_thoi_viec', 'ngay_nop_don_thoi_viec', 'thoi_han_den_han_tai_bo_nhiem', 'ngay_canh_bao_qt_lam_viec', 'tham_nien_nam', 'tham_nien_thang', 'tuoi'],
    'hashdiff_qlns_nguoi_lao_dong_info_luong_thuong': ['ma_thang_luong', 'ma_ngach_luong', 'ma_bac_luong', 'luong_chuc_danh', 'thuong_nang_suat', 'thu_nhap', 'ho_tro_xang_xe', 'phu_cap_doc_hai', 'ho_tro_tien_an_giua_ca', 'ho_tro_dien_thoai', 'phu_cap_thu_hut', 'tam_ung_hieu_suat'],
    'hashdiff_qlns_nguoi_lao_dong_info_ky_luat': ['tinh_trang_ky_luat', 'ma_tinh_trang_ky_luat', 'tg_thi_hanh_kl', 'tg_ket_thuc_thi_hanh_kl', 'kq_danh_gia_gan_nhat', 'kqdg_ky_truoc']
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
{%- set columns = get_columns(source(source_name, source_table)) -%}
{%- set cols_name = [] -%}
{%- for column in columns -%}{%- do cols_name.append(column.name) -%}{%- endfor -%}

{%- set raw_sql %}
select
    --HASH KEY
    {{ hash_column(business_key_cols, source_name) }} as hashkey,

    --ALL COLUMNS FROM SOURCE TABLE
    {% for column in columns %}src.{{ column.name }},
    {% endfor %}

    --HASHDIFF FULL
    {{ hash_column(cols_name, source_name) }} as hashdiff_full,

    --HASHDIFF SATELLITES
    {% for k, v in hashdiff_satellite_dict.items() %}{{ hash_column(v, source_name) }} as {{ k }},
    {% endfor %}

    --TIME & SOURCE COLUMNS
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    '{{ source_name }}' as record_source,
    cast(current_timestamp as timestamp) as load_timestamp

from {{ source(source_name, source_table) }} src
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY MA_NHAN_VIEN
    ORDER BY etl_time DESC
) = 1
{%- endset %}

{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=hashdiff_satellite_dict,
    source_event_date_col=source_event_date_col,
    source_name=source_name,
    raw_sql=raw_sql
) }}
{% endif -%}
