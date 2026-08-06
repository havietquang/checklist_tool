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
    alias = 'sat_giao_dich_tht_nhom_chinh_sach_the',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
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
{% set source_table = 'tht_nhom_chinh_sach_the' %}
{% set hashdiff_col = 'hashdiff_giao_dich_tht_nhom_chinh_sach_the' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set raw_sql -%}

SELECT
    gd.hashkey AS {{ hub_hashkey }},
    src.{{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    src.ma_key AS ma_key,
    src.nhom_chinh_sach_ten AS nhom_chinh_sach_ten,
    src.ngay_tao AS ngay_tao,
    src.size_chi_tiet_1 AS size_chi_tiet_1,
    src.is_the_phu AS is_the_phu,
    src.ma_nhom_chinh_sach AS ma_nhom_chinh_sach,
    src.giay_to_the_phu AS giay_to_the_phu,
    src.ma_chi_tiet_1 AS ma_chi_tiet_1,
    src.chi_tiet_1_ten AS chi_tiet_1_ten,
    src.ma_chi_tiet_2 AS ma_chi_tiet_2,
    src.chi_tiet_2_ten AS chi_tiet_2_ten,
    src.san_pham_the AS san_pham_the,
    src.id_the_chinh AS id_the_chinh
FROM {{ ref('v_stg_bpm_tht_nhom_chinh_sach_the') }} src
JOIN {{ ref('v_stg_bpm_giao_dich') }} gd
    ON src.gd_id = gd.gd_id
WHERE src.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

