/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record (thuong: hub_hashkey + hashdiff)
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['bpm'] = filter khi run (dbt run --select tag:bpm)
====================================================================
*/

{{ config(
    alias = 'sat_tsbd_giaodich_chi_tiet',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['tsbd_giaodich_chinh_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase1', 'all']
) }}

/*
========================================================================
SATELLITE MACRO PARAMETERS
========================================================================
  - source_name         : Ten he thong nguon, dung de tao gia tri cho cot `record_source`.
  - source_table        : Ten bang nghiep vu o he thong nguon.
  - hashdiff_col        : Ten cot hashdiff da duoc tinh san o tang staging.
  - hub_hashkey         : Ten khoa hash dung de lien ket ve bang Hub/Link.
  - source_model        : Model staging lam nguon de doc du lieu.
  - list_cols           : Danh sach cac cot nghiep vu duoc luu trong Satellite.
  - raw_sql (optional)  : Cau SQL tu viet trong truong hop logic phuc tap hoac dac biet.
========================================================================
*/

{% set source_name = 'bpm' %}
{% set source_table = 'tsbd_giaodich_chitiet' %}
{% set hashdiff_col = 'hashdiff_tsbd_giaodich_chi_tiet' %}
{% set hub_hashkey = 'tsbd_giaodich_chinh_hashkey' %}
{% set raw_sql -%}

SELECT
    c.hashkey AS {{ hub_hashkey }},
    ct.{{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    ct.ma_key AS ma_key,
    ct.ngay_bat_dau_totrinh AS ngay_bat_dau_totrinh,
    ct.ngay_ket_thuc_totrinh AS ngay_ket_thuc_totrinh,
    ct.cb_lap AS cb_lap,
    ct.loai_dvdg AS loai_dvdg,
    ct.y_kien_id AS y_kien_id,
    ct.ngay_tao AS ngay_tao,
    ct.trang_thai_to_trinh AS trang_thai_to_trinh,
    ct.ngay_bat_dau_totrinh_kiemtra AS ngay_bat_dau_totrinh_kiemtra,
    ct.ngay_ket_thuc_totrinh_kiemtra AS ngay_ket_thuc_totrinh_kiemtra,
    ct.cb_kiemtra AS cb_kiemtra,
    ct.trang_thai_to_trinh_kiem_tra AS trang_thai_to_trinh_kiem_tra,
    ct.diem_vitri_1 AS diem_vitri_1,
    ct.diem_vitri_2 AS diem_vitri_2,
    ct.diem_vitri_3 AS diem_vitri_3,
    ct.diem_vitri_4 AS diem_vitri_4,
    ct.diem_vitri_5 AS diem_vitri_5,
    ct.diem_vitri_6 AS diem_vitri_6,
    ct.user_vitri_1 AS user_vitri_1,
    ct.user_vitri_2 AS user_vitri_2,
    ct.user_vitri_3 AS user_vitri_3,
    ct.user_vitri_4 AS user_vitri_4,
    ct.user_vitri_5 AS user_vitri_5,
    ct.user_vitri_6 AS user_vitri_6,
    ct.khu_vuc_nv_id AS khu_vuc_nv_id,
    ct.khoang_cach_dia_ban AS khoang_cach_dia_ban,
    ct.he_so_dia_ban AS he_so_dia_ban,
    ct.sla_tructiep AS sla_tructiep,
    ct.sla_giantiep AS sla_giantiep,
    ct.thoi_gian_cbktkqdg AS thoi_gian_cbktkqdg,
    ct.thoi_gian_tbpktkqdg AS thoi_gian_tbpktkqdg,
    ct.thoi_gian_cbpqltsbd AS thoi_gian_cbpqltsbd,
    ct.thoi_gian_tbppqltsbd AS thoi_gian_tbppqltsbd,
    ct.ly_do AS ly_do,
    ct.thoi_gian_di_chuyen AS thoi_gian_di_chuyen,
    ct.thoi_gian_khao_sat AS thoi_gian_khao_sat,
    ct.tong_thoi_gian_khao_sat AS tong_thoi_gian_khao_sat
FROM {{ ref('v_stg_bpm_tsbd_giaodich_chitiet') }} ct
JOIN {{ ref('v_stg_bpm_tsbd_giaodich_chinh') }} c
    ON ct.ma_giao_dich = c.ma_giao_dich
WHERE ct.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

