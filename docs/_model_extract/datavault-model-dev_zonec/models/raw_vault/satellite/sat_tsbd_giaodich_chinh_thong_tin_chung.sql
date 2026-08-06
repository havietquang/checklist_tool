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
    alias = 'sat_tsbd_giaodich_chinh_thong_tin_chung',
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
{% set hashdiff_col = 'hashdiff_tsbd_giaodich_chinh_thong_tin_chung' %}
{% set hub_hashkey = 'tsbd_giaodich_chinh_hashkey' %}
{% set source_model = 'v_stg_bpm_tsbd_giaodich_chinh' %}
{% set list_cols = [
    'kh_han_che','loai_giao_dich','muc_dich_vay','ngay_tao','gd_pdtd_tham_chieu_id','ma_gd_pdtd_tham_chieu','tai_san_id','nguoi_tao','trang_thai','giao_dich_goc','trang_thai_phe_duyet','nhom_san_pham_id','deactive','diem_phan_cong','dvkd_khoi_tao','can_bo_phe_duyet','can_bo_dang_xly','dvkd_dang_xly','quy_trinh','ly_do_dexuat','process_id','ngay_cap_nhat','nguoi_cap_nhat','ngay_chuyen_task_cbkt','bspo_id','luong_xu_ly','muc_dich_tham_dinh_id','ngay_de_xuat_pqlts_td','ngay_bat_dau_pqlts_td','gio_bat_dau_pqlts_td','phut_bat_dau_pqlts_td','muc_dich_tham_dinh_khac_ten','ngay_bat_dau_pqlts_td_string','ngay_hoan_thanh_pqlts_td','nhom_kh_uu_tien','sdt_nguoi_hd_khao_sat','so_bien_ban_dinh_gia','tai_san_du_dk_thamdinh','tai_san_tdtt','ts_cung_db_dvkd','ts_moi'
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

