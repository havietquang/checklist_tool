{{ config(
    alias = 'sat_giao_dich_tdcn_khoan_cap_td_the',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tdcn_khoan_cap_td_the' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set raw_sql -%}
SELECT
    src.hashkey AS {{ hub_hashkey }},
    src.hashdiff_giao_dich_tdcn_khoan_cap_td_the AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    src.id AS id,
    src.nhom_the AS nhom_the,
    src.hm_the_dx AS hm_the_dx,
    src.nghia_vu_tra_no_kh AS nghia_vu_tra_no_kh,
    src.dti AS dti,
    src.ltv AS ltv,
    src.tong_muc_cap_td_dx AS tong_muc_cap_td_dx,
    src.rrtd_sp_co_va_khong_tsbd AS rrtd_sp_co_va_khong_tsbd,
    src.rrtd_sp_khong_tsbd AS rrtd_sp_khong_tsbd,
    src.rrtd_sp_thong_thuong AS rrtd_sp_thong_thuong,
    src.rrtd_sp_thong_thuong_ko_tsbd AS rrtd_sp_thong_thuong_ko_tsbd,
    src.rrtd_kh_tai_ocb AS rrtd_kh_tai_ocb,
    src.nguoi_tao AS nguoi_tao,
    src.ngay_tao AS ngay_tao,
    src.cap_td_kem_khoan_vay AS cap_td_kem_khoan_vay,
    src.hm_the_dx_pd AS hm_the_dx_pd,
    src.rrtd_sp_co_va_khong_tsbd_pd AS rrtd_sp_co_va_khong_tsbd_pd,
    src.rrtd_sp_khong_tsbd_pd AS rrtd_sp_khong_tsbd_pd
FROM {{ ref('v_stg_bpm_tdcn_khoan_cap_td_the') }} src
WHERE src.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}
