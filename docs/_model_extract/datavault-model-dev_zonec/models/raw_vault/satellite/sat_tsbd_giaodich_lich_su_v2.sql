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
    alias = 'sat_tsbd_giaodich_lich_su_v2',
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
{% set source_table = 'tsbd_giaodich_lich_su_v2' %}
{% set hashdiff_col = 'hashdiff_tsbd_giaodich_lich_su_v2' %}
{% set hub_hashkey = 'tsbd_giaodich_chinh_hashkey' %}
{% set raw_sql -%}

SELECT
    c.hashkey AS {{ hub_hashkey }},
    src.{{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    src.ma_key AS ma_key,
    src.id AS id,
    src.gd_tsbd_id AS gd_tsbd_id,
    src.user_thuc_hien AS user_thuc_hien,
    src.username_thuc_hien AS username_thuc_hien,
    src.role_thuc_hien AS role_thuc_hien,
    src.user_chuyen_toi AS user_chuyen_toi,
    src.username_chuyen_toi AS username_chuyen_toi,
    src.role_chuyen_toi AS role_chuyen_toi,
    src.ngay_nhan_task AS ngay_nhan_task,
    src.task_id AS task_id,
    src.thao_tac_id AS thao_tac_id,
    src.trang_thai_ket_thuc AS trang_thai_ket_thuc,
    src.trang_thai_bat_dau AS trang_thai_bat_dau,
    src.ngay_bat_dau AS ngay_bat_dau,
    src.ngay_ket_thuc AS ngay_ket_thuc,
    src.bo_sung_tdv AS bo_sung_tdv,
    src.bo_sung_cbpqltsbd AS bo_sung_cbpqltsbd,
    src.bo_sung_tbppqltsbd AS bo_sung_tbppqltsbd,
    src.bo_sung_y_kien_tdv AS bo_sung_y_kien_tdv,
    src.bo_sung_y_kien_cbktkqdg AS bo_sung_y_kien_cbktkqdg,
    src.ma_luong_dvdg AS ma_luong_dvdg,
    src.ten_luong_dvdg AS ten_luong_dvdg,
    src.chu_thich AS chu_thich,
    src.trang_thai AS trang_thai,
    src.nguoi_tao AS nguoi_tao,
    src.ngay_tao AS ngay_tao,
    src.thoi_gian_thuc_hien AS thoi_gian_thuc_hien
FROM {{ ref('v_stg_bpm_tsbd_giaodich_lich_su_v2') }} src
JOIN {{ ref('v_stg_bpm_tsbd_giaodich_chinh') }} c
    ON src.ma_giao_dich = c.ma_giao_dich
WHERE src.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

