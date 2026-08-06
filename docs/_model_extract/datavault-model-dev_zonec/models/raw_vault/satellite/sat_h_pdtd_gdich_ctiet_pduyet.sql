{{ config(
    alias = 'sat_h_pdtd_gdich_ctiet_pduyet',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['pdtd_nhom_giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'h_pdtd_gdich_ctiet_pduyet' %}
{% set hub_hashkey = 'pdtd_nhom_giao_dich_hashkey' %}
{% set raw_sql -%}
SELECT
    {{ hash_column(['nvl(pdtd.ma_giao_dich, CAST(src.nhom_giao_dich_id AS string))'], source_name) }} AS {{ hub_hashkey }},
    src.hashdiff_h_pdtd_gdich_ctiet_pduyet AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    src.ma_key AS ma_key,
    src.trang_thai_bat_dau_id AS trang_thai_bat_dau_id,
    src.ngay_bat_dau AS ngay_bat_dau,
    src.ngay_ket_thuc AS ngay_ket_thuc,
    src.nguoi_thao_tac_id AS nguoi_thao_tac_id,
    src.trang_thai_ket_thuc_id AS trang_thai_ket_thuc_id,
    src.ma_giao_dich AS ma_giao_dich,
    src.nguoi_thao_tac AS nguoi_thao_tac,
    src.process_id AS process_id,
    src.role_id AS role_id,
    src.ket_qua_id AS ket_qua_id,
    src.ten_tac_vu AS ten_tac_vu,
    src.role_tiep_theo_id AS role_tiep_theo_id,
    src.so_lan AS so_lan,
    src.thoi_gian_thuc_hien AS thoi_gian_thuc_hien
FROM {{ ref('v_stg_bpm_h_pdtd_gdich_ctiet_pduyet') }} src
LEFT JOIN {{ ref('v_stg_bpm_pdtd_nhom_giao_dich') }} pdtd
    ON src.nhom_giao_dich_id = pdtd.id
WHERE src.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND src.nhom_giao_dich_id <> 0
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql,
    list_cols=['ma_key']
) }}
