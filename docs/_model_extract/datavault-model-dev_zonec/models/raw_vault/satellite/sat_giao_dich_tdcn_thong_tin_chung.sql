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
    alias = 'sat_giao_dich_tdcn_thong_tin_chung',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'hashdiff', 'source_event_date'],
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
{% set source_table = 'tdcn_thong_tin_chung' %}
{% set hashdiff_col = 'hashdiff_giao_dich_tdcn_thong_tin_chung' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set raw_sql -%}

SELECT
    gd.hashkey AS {{ hub_hashkey }},
    src.{{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    src.id AS id,
    src.xep_hang_tin_dung AS xep_hang_tin_dung,
    src.tt_ngoai_le AS tt_ngoai_le,
    src.hinh_thuc_bd AS hinh_thuc_bd,
    src.luong_xu_ly AS luong_xu_ly,
    src.luong_soan_thao AS luong_soan_thao,
    src.luong_phe_duyet AS luong_phe_duyet,
    src.is_thay_doi_tt AS is_thay_doi_tt,
    src.ngay_tao AS ngay_tao,
    src.nguoi_tao AS nguoi_tao,
    src.so_cap_duyet AS so_cap_duyet,
    src.vi_tri_buoc_giao_dich AS vi_tri_buoc_giao_dich,
    src.rating_id AS rating_id,
    src.noi_cu_tru AS noi_cu_tru,
    src.is_dong_vay AS is_dong_vay,
    src.tong_thu_nhap_tra_no AS tong_thu_nhap_tra_no,
    src.no_thang_dau AS no_thang_dau,
    src.no_hien_co AS no_hien_co,
    src.no_tai_tctd_khac AS no_tai_tctd_khac,
    src.dti AS dti,
    src.so_tuoi AS so_tuoi,
    src.dieu_kien_sp_id AS dieu_kien_sp_id,
    src.ly_do AS ly_do,
    src.trang_thai_tdtt AS trang_thai_tdtt,
    src.thoi_diem_tdtt AS thoi_diem_tdtt,
    src.kctd_ngoai_le_cho_vay AS kctd_ngoai_le_cho_vay,
    src.kctd_ngoai_le_tin_dung AS kctd_ngoai_le_tin_dung,
    src.kctd_ngoai_le_xep_hang_kh AS kctd_ngoai_le_xep_hang_kh,
    src.kctd_ngoai_le_sp_tin_dung AS kctd_ngoai_le_sp_tin_dung,
    src.kctd_trinh_ybtd AS kctd_trinh_ybtd,
    src.tsbd_phai_duoc_ubtd_pd AS tsbd_phai_duoc_ubtd_pd,
    src.thanh_vien_pos AS thanh_vien_pos,
    src.thanh_vien_ubtd AS thanh_vien_ubtd,
    src.muc_dich_xhtd AS muc_dich_xhtd,
    src.is_dong_vay_nhphoi AS is_dong_vay_nhphoi,
    src.soan_thao_hs AS soan_thao_hs,
    src.xu_ly_hs AS xu_ly_hs,
    src.is_phap_che AS is_phap_che,
    src.loai_gd AS loai_gd,
    src.dvi_trien_khai AS dvi_trien_khai,
    src.kh_adgiam_tat_rb AS kh_adgiam_tat_rb
FROM {{ ref('v_stg_bpm_tdcn_thong_tin_chung') }} src
JOIN {{ ref('v_stg_bpm_giao_dich') }} gd
    ON src.gd_id = gd.gd_id
WHERE src.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

