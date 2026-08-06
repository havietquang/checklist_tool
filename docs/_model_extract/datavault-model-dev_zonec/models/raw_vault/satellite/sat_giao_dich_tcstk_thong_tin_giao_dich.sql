{{ config(
    alias = 'sat_giao_dich_tcstk_thong_tin_giao_dich',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tcstk_thong_tin_giao_dich' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set raw_sql -%}
SELECT
    src.hashkey AS {{ hub_hashkey }},
    src.hashdiff_giao_dich_tcstk_thong_tin_giao_dich AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    src.id AS id,
    src.ma_gd_omni AS ma_gd_omni,
    src.nguoi_tao_gd_omni AS nguoi_tao_gd_omni,
    src.ngay_tao_gd_omni AS ngay_tao_gd_omni,
    src.so_tien_de_nghi AS so_tien_de_nghi,
    src.loai_tien_dn AS loai_tien_dn,
    src.so_tien_de_xuat AS so_tien_de_xuat,
    src.loai_tien_dx AS loai_tien_dx,
    src.so_tien_hm_pd AS so_tien_hm_pd,
    src.loai_tien_pd AS loai_tien_pd,
    src.trang_thai_gd AS trang_thai_gd,
    src.khach_hang_id AS khach_hang_id,
    src.tt_tai_khoan_tc AS tt_tai_khoan_tc,
    src.tong_so_tien_vay AS tong_so_tien_vay,
    src.ngay_bd_hm AS ngay_bd_hm,
    src.han_muc_tc_bd AS han_muc_tc_bd,
    src.hm_tc_con_lai AS hm_tc_con_lai,
    src.hm_dc_da_sd AS hm_dc_da_sd,
    src.ngay_tat_toan AS ngay_tat_toan,
    src.lai_suat_khi_tat_toan AS lai_suat_khi_tat_toan,
    src.so_tien_khi_tat_toan AS so_tien_khi_tat_toan,
    src.ma_don_vi_kd_ql AS ma_don_vi_kd_ql,
    src.ma_don_vi_khoi_tao AS ma_don_vi_khoi_tao,
    src.don_vi_kt AS don_vi_kt,
    src.ngay_kt_hm AS ngay_kt_hm,
    src.nguoi_pd AS nguoi_pd,
    src.ngay_pd AS ngay_pd,
    src.loai_gd AS loai_gd,
    src.laisuat AS laisuat,
    src.ngay_tao AS ngay_tao,
    src.nguoi_tao AS nguoi_tao,
    src.ngay_cap_nhat AS ngay_cap_nhat,
    src.nguoi_cap_nhat AS nguoi_cap_nhat,
    src.is_delete AS is_delete,
    src.trang_thai_gd_omni AS trang_thai_gd_omni,
    src.loai_gd_id AS loai_gd_id
FROM {{ ref('v_stg_bpm_tcstk_thong_tin_giao_dich') }} src
WHERE src.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}
