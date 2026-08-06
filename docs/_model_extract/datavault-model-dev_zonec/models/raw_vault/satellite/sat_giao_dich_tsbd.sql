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
    alias = 'sat_giao_dich_tsbd',
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
{% set source_table = 'giao_dich_tsbd' %}
{% set hashdiff_col = 'hashdiff_giao_dich_tsbd' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set raw_sql -%}

SELECT
    gd.hashkey AS {{ hub_hashkey }},
    src.{{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    src.ma_tsbd AS ma_tsbd,
    src.quy_trinh AS quy_trinh,
    src.ngay_tao AS ngay_tao,
    src.ngay_cap_nhat AS ngay_cap_nhat,
    src.nguoi_tao AS nguoi_tao,
    src.ngay_phat_hanh AS ngay_phat_hanh,
    src.ngay_den_han AS ngay_den_han,
    src.gia_tri AS gia_tri,
    src.loai_tien_gui AS loai_tien_gui,
    src.ti_le_bd AS ti_le_bd,
    src.tinh_trang_phong_toa AS tinh_trang_phong_toa,
    src.muc_bao_dam AS muc_bao_dam,
    src.chu_so_huu AS chu_so_huu,
    src.loai_tien_t24 AS loai_tien_t24,
    src.cif AS cif,
    src.cmnd AS cmnd
FROM {{ ref('v_stg_bpm_giao_dich_tsbd') }} src
JOIN {{ ref('v_stg_bpm_giao_dich') }} gd
    ON src.gd_id = gd.gd_id
WHERE src.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

