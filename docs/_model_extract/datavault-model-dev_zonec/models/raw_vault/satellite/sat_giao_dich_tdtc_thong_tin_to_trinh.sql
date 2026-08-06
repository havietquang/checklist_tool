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
    alias = 'sat_giao_dich_tdtc_thong_tin_to_trinh',
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
{% set source_table = 'tdtc_thong_tin_to_trinh' %}
{% set hashdiff_col = 'hashdiff_giao_dich_tdtc_thong_tin_to_trinh' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set raw_sql -%}

SELECT
    gd.hashkey AS {{ hub_hashkey }},
    src.{{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    src.id AS id,
    src.khach_hang_id AS khach_hang_id,
    src.san_pham_id AS san_pham_id,
    src.hang_kh AS hang_kh,
    src.quoc_tich AS quoc_tich,
    src.ho_khau_thuong_tru AS ho_khau_thuong_tru,
    src.noi_o_hien_tai AS noi_o_hien_tai,
    src.tinh_thanh_hien_tai AS tinh_thanh_hien_tai,
    src.sdt AS sdt,
    src.email AS email,
    src.thu_nhap_bq_thang AS thu_nhap_bq_thang,
    src.loai_hinh_dn AS loai_hinh_dn,
    src.thoi_gian_dong_thue AS thoi_gian_dong_thue,
    src.dn_nhom_no_hien_tai AS dn_nhom_no_hien_tai,
    src.dn_ls_no_nhom_2_tro_len AS dn_ls_no_nhom_2_tro_len,
    src.cn_nhom_no_hien_tai AS cn_nhom_no_hien_tai,
    src.cn_ls_no_can_chu_y AS cn_ls_no_can_chu_y,
    src.cn_ls_no_xau AS cn_ls_no_xau,
    src.can_doi_tra_no AS can_doi_tra_no,
    src.tong_rr_hien_tai AS tong_rr_hien_tai,
    src.so_du_no_hien_tai AS so_du_no_hien_tai,
    src.tong_rr_dx AS tong_rr_dx,
    src.de_xuat_moi AS de_xuat_moi,
    src.thoi_han_dx_moi AS thoi_han_dx_moi,
    src.kctd_so_tien AS kctd_so_tien,
    src.kctd_muc_dich_vay AS kctd_muc_dich_vay,
    src.kctd_thoi_han_vay AS kctd_thoi_han_vay,
    src.kctd_ls_cho_vay AS kctd_ls_cho_vay,
    src.kctd_phuong_thuc_tra_no AS kctd_phuong_thuc_tra_no,
    src.ty_le_tai_tro_toi_da AS ty_le_tai_tro_toi_da,
    src.dk_tk_payroll AS dk_tk_payroll,
    src.dti AS dti,
    src.ngay_tao AS ngay_tao,
    src.nguoi_tao AS nguoi_tao,
    src.ten_doanh_nghiep AS ten_doanh_nghiep,
    src.ma_so_thue_dn AS ma_so_thue_dn,
    src.tong_thu_nhap_bq_thang AS tong_thu_nhap_bq_thang,
    src.xep_hang_kh AS xep_hang_kh,
    src.hinh_thuc_gn AS hinh_thuc_gn,
    src.do_tuoi_kh AS do_tuoi_kh,
    src.so_tien_pd AS so_tien_pd,
    src.tong_rrtd_pd AS tong_rrtd_pd,
    src.xep_hang_dn AS xep_hang_dn,
    src.tinh_thanh_cong_tac AS tinh_thanh_cong_tac,
    src.vi_tri_cong_tac AS vi_tri_cong_tac,
    src.tong_tn_bq_thang_bds AS tong_tn_bq_thang_bds,
    src.dti_khong_tsbd AS dti_khong_tsbd,
    src.nhp_ls_no_can_chu_y AS nhp_ls_no_can_chu_y,
    src.nhp_ls_no_xau AS nhp_ls_no_xau,
    src.nhp_nhom_no_hien_tai AS nhp_nhom_no_hien_tai,
    src.rating_id AS rating_id,
    src.xhtd_id AS xhtd_id
FROM {{ ref('v_stg_bpm_tdtc_thong_tin_to_trinh') }} src
JOIN {{ ref('v_stg_bpm_giao_dich') }} gd
    ON src.gd_id = gd.gd_id
WHERE src.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

