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
    alias = 'sat_giaodich_sla',
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
{% set source_table = 'giao_dich_sla' %}
{% set hashdiff_col = 'hashdiff_giaodich_sla' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set raw_sql -%}

SELECT
    gd.hashkey AS {{ hub_hashkey }},
    sla.{{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    sla.quy_trinh AS quy_trinh,
    sla.sla AS sla,
    sla.thoi_gian_xl_vitri_1 AS thoi_gian_xl_vitri_1,
    sla.thoi_gian_xl_vitri_2 AS thoi_gian_xl_vitri_2,
    sla.thoi_diem_nhan_vitri_1 AS thoi_diem_nhan_vitri_1,
    sla.thoi_diem_nhan_vitri_2 AS thoi_diem_nhan_vitri_2,
    sla.thoi_diem_nhan_vitri_1_cuoi AS thoi_diem_nhan_vitri_1_cuoi,
    sla.thoi_diem_nhan_vitri_2_cuoi AS thoi_diem_nhan_vitri_2_cuoi,
    sla.thoi_gian_xl_vitri_3 AS thoi_gian_xl_vitri_3,
    sla.thoi_gian_xl_vitri_4 AS thoi_gian_xl_vitri_4,
    sla.thoi_diem_nhan_vitri_3 AS thoi_diem_nhan_vitri_3,
    sla.thoi_diem_nhan_vitri_4 AS thoi_diem_nhan_vitri_4,
    sla.thoi_diem_nhan_vitri_3_cuoi AS thoi_diem_nhan_vitri_3_cuoi,
    sla.thoi_diem_nhan_vitri_4_cuoi AS thoi_diem_nhan_vitri_4_cuoi,
    sla.thoi_gian_den_han AS thoi_gian_den_han,
    sla.sla_vitri_2 AS sla_vitri_2,
    sla.sla_vitri_3 AS sla_vitri_3,
    sla.sla_vitri_4 AS sla_vitri_4,
    sla.sla_vitri_5 AS sla_vitri_5,
    sla.thoi_gian_xl_vitri_5 AS thoi_gian_xl_vitri_5,
    sla.thoi_diem_nhan_vitri_5 AS thoi_diem_nhan_vitri_5,
    sla.thoi_diem_nhan_vitri_5_cuoi AS thoi_diem_nhan_vitri_5_cuoi,
    sla.trang_thai AS trang_thai,
    sla.thoi_gian_xl_vitri_6 AS thoi_gian_xl_vitri_6,
    sla.thoi_diem_nhan_vitri_6 AS thoi_diem_nhan_vitri_6,
    sla.thoi_diem_nhan_vitri_6_cuoi AS thoi_diem_nhan_vitri_6_cuoi,
    sla.thoi_gian_xl_vitri_7 AS thoi_gian_xl_vitri_7,
    sla.thoi_diem_nhan_vitri_7 AS thoi_diem_nhan_vitri_7,
    sla.thoi_diem_nhan_vitri_7_cuoi AS thoi_diem_nhan_vitri_7_cuoi,
    sla.sla_vitri_8 AS sla_vitri_8,
    sla.thoi_gian_xl_vitri_8 AS thoi_gian_xl_vitri_8,
    sla.thoi_diem_nhan_vitri_8 AS thoi_diem_nhan_vitri_8,
    sla.thoi_diem_nhan_vitri_8_cuoi AS thoi_diem_nhan_vitri_8_cuoi,
    sla.sla_vitri_9 AS sla_vitri_9,
    sla.thoi_gian_xl_vitri_9 AS thoi_gian_xl_vitri_9,
    sla.thoi_diem_nhan_vitri_9 AS thoi_diem_nhan_vitri_9,
    sla.thoi_diem_nhan_vitri_9_cuoi AS thoi_diem_nhan_vitri_9_cuoi,
    sla.sla_vitri_12 AS sla_vitri_12,
    sla.thoi_gian_xl_vitri_12 AS thoi_gian_xl_vitri_12,
    sla.thoi_diem_nhan_vitri_12 AS thoi_diem_nhan_vitri_12,
    sla.thoi_diem_nhan_vitri_12_cuoi AS thoi_diem_nhan_vitri_12_cuoi,
    sla.sla_vitri_14 AS sla_vitri_14,
    sla.thoi_gian_xl_vitri_14 AS thoi_gian_xl_vitri_14,
    sla.thoi_diem_nhan_vitri_14 AS thoi_diem_nhan_vitri_14,
    sla.thoi_diem_nhan_vitri_14_cuoi AS thoi_diem_nhan_vitri_14_cuoi
FROM {{ ref('v_stg_bpm_giao_dich_sla') }} sla
INNER JOIN {{ ref('v_stg_bpm_giao_dich') }} gd
    ON sla.gd_id = gd.gd_id
WHERE sla.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

