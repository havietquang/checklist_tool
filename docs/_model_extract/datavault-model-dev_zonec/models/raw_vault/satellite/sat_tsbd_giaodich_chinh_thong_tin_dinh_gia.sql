/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record mới/thay đổi
                    : 'table' = full load
                    : 'view' = chỉ tạo view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chỉ insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khóa định danh record (thường: hub_hashkey + hashdiff)
skip_matched_step   : true = bỏ record không đổi → tăng performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['bpm'] = filter khi run (dbt run --select tag:bpm)
====================================================================
*/

{{ config(
    alias = 'sat_tsbd_giaodich_chinh_thong_tin_dinh_gia',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['tsbd_giaodich_chinh_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase1', 'all']
) }}

/*
========================================================================
SATELLITE MACRO PARAMETERS
========================================================================
  - source_name         : Tên hệ thống nguồn, dùng để tạo giá trị cho cột `record_source`.
  - source_table        : Tên bảng nghiệp vụ ở hệ thống nguồn.
  - hashdiff_col        : Tên cột hashdiff đã được tính sẵn ở tầng staging.
  - hub_hashkey         : Tên khóa hash dùng để liên kết về bảng Hub.
  - source_model        : Model staging làm nguồn để đọc dữ liệu.
  - list_cols           : Danh sách các cột nghiệp vụ được lưu trong Satellite.
  - raw_sql (optional)  : Câu SQL tự viết trong trường hợp logic phức tạp hoặc đặc biệt.
*/

{% set source_name = 'bpm' %}
{% set source_table = 'tsbd_giaodich_chinh' %}
{% set hashdiff_col = 'hashdiff_tsbd_giaodich_chinh_thong_tin_dinh_gia' %}
{% set hub_hashkey = 'tsbd_giaodich_chinh_hashkey' %}
{% set source_model = 'v_stg_bpm_tsbd_giaodich_chinh' %}
{% set list_cols = [
    'hoan_thanh',
    'id_tinh_diem_pc_ktkqdg',
    'is_xn_tgks_tdtt',
    'json_link_tai_lieu',
    'loai_dvdg',
    'dvdg_ben_3_id',
    'dvdg_khac',
    'dvdg_khac_ten',
    'gia_tri_dg',
    'ngay_hoan_tat_dg',
    'don_gia_dat_dg',
    'dinh_gia_moi',
    'ten_nguoi_hd_khao_sat',
    'yeu_cau_ben_3_dg',
    'yeu_cau_cap_phe_duyet',
    'don_gia_dg_id',
    'y_kien_dvkd',
    'y_kien_phe_duyet',
    'dvdg_ben_3_de_xuat_id',
    'dvdg_de_xuat_khac',
    'dvdg_de_xuat_khac_ten',
    'ket_qua_danh_gia',
    'nguyen_tac_tinh_diem_pc',
    'tong_hmrr_kh_dexuat'
] %}
{% set raw_sql = None %}

/* 
Truong hop khong su dung marco satellite, co the su dung raw_sql nhu ben duoi de 
viet SQL thu cong, sau do truyen vao macro satellite de tao satellite
*/
{{ satellite(
    source_model=source_model,
    source_name=source_name,
    source_table=source_table,
    hub_hashkey=hub_hashkey,
    hashdiff_name=hashdiff_col,
    list_cols=list_cols
) }}

