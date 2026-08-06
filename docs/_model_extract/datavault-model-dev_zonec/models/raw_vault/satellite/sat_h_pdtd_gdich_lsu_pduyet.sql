{{ config(
    alias = 'sat_h_pdtd_gdich_lsu_pduyet',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['pdtd_nhom_giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'h_pdtd_gdich_lsu_pduyet' %}
{% set hub_hashkey = 'pdtd_nhom_giao_dich_hashkey' %}
{% set raw_sql -%}
SELECT
    {{ hash_column(['nvl(pdtd.ma_giao_dich, CAST(src.nhom_giao_dich_id AS string))'], source_name) }} AS {{ hub_hashkey }},
    src.hashdiff_h_pdtd_gdich_lsu_pduyet AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    src.ma_key AS ma_key,
    src.dvi_phe_duyet AS dvi_phe_duyet,
    src.nguoi_phe_duyet AS nguoi_phe_duyet,
    src.ngay_phe_duyet AS ngay_phe_duyet,
    src.noi_dung_phe_duyet AS noi_dung_phe_duyet,
    src.chu_thich AS chu_thich,
    src.trang_thai AS trang_thai,
    src.dang_phe_duyet AS dang_phe_duyet,
    src.phe_duyet_id AS phe_duyet_id,
    src.noi_dung_phe_duyet1 AS noi_dung_phe_duyet1,
    src.noi_dung_phe_duyet2 AS noi_dung_phe_duyet2,
    src.noi_dung_phe_duyet3 AS noi_dung_phe_duyet3,
    src.noi_dung_phe_duyet4 AS noi_dung_phe_duyet4,
    src.noi_dung_phe_duyet5 AS noi_dung_phe_duyet5,
    src.noi_dung_phe_duyet6 AS noi_dung_phe_duyet6,
    src.noi_dung_phe_duyet7 AS noi_dung_phe_duyet7,
    src.noi_dung_phe_duyet8 AS noi_dung_phe_duyet8,
    src.noi_dung_phe_duyet9 AS noi_dung_phe_duyet9,
    src.nhom_id AS nhom_id,
    src.tham_quyen AS tham_quyen
FROM {{ ref('v_stg_bpm_h_pdtd_gdich_lsu_pduyet') }} src
LEFT JOIN {{ ref('v_stg_bpm_pdtd_nhom_giao_dich') }} pdtd
    ON src.nhom_giao_dich_id = pdtd.id
WHERE src.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql,
    list_cols=['ma_key']
) }}
