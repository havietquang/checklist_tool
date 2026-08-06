{{ config(
    alias = 'sat_giao_dich_tcstk_thong_tin_chung',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['giao_dich_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tcstk_thong_tin_chung' %}
{% set hub_hashkey = 'giao_dich_hashkey' %}
{% set raw_sql -%}
SELECT
    src.hashkey AS {{ hub_hashkey }},
    src.hashdiff_giao_dich_tcstk_thong_tin_chung AS hashdiff,
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
    src.ngay_bd_hm AS ngay_bd_hm,
    src.ngay_kt_hm AS ngay_kt_hm,
    src.nguoi_pd AS nguoi_pd,
    src.ngay_pd AS ngay_pd,
    src.loai_gd AS loai_gd,
    src.ngay_tao AS ngay_tao,
    src.nguoi_tao AS nguoi_tao,
    src.ngay_cap_nhat AS ngay_cap_nhat,
    src.nguoi_cap_nhat AS nguoi_cap_nhat,
    src.is_delete AS is_delete,
    src.trang_thai_gd_omni AS trang_thai_gd_omni,
    src.action AS action,
    src.tkwa AS tkwa,
    src.biendols AS biendols,
    src.ngay_kh_dx AS ngay_kh_dx,
    src.ma_hm AS ma_hm,
    src.ma_lkq AS ma_lkq,
    src.ma_don_vi_khoi_tao AS ma_don_vi_khoi_tao,
    src.decesion AS decesion,
    src.don_vi_khoi_tao AS don_vi_khoi_tao,
    src.next_decesion AS next_decesion,
    src.so_cif AS so_cif,
    src.ten_kh AS ten_kh,
    src.trang_thai_hoat_dong AS trang_thai_hoat_dong,
    src.so_tk_tc AS so_tk_tc,
    src.email AS email,
    src.sodt AS sodt,
    src.trang_thai AS trang_thai,
    src.laisuat AS laisuat,
    src.is_tat_toan AS is_tat_toan,
    src.nghiep_vu AS nghiep_vu,
    src.ma_gd_mo AS ma_gd_mo,
    src.no_goc AS no_goc,
    src.no_lai AS no_lai,
    src.du_no_goc_api AS du_no_goc_api,
    src.du_no_lai_api AS du_no_lai_api,
    src.ngay_tat_toan AS ngay_tat_toan,
    src.tong_du_no AS tong_du_no,
    src.loai_tien AS loai_tien,
    src.list_tai_lieu AS list_tai_lieu,
    src.list_ts AS list_ts,
    src.is_tao_tk_tc AS is_tao_tk_tc,
    src.is_tao_lkq AS is_tao_lkq,
    src.is_tao_hm AS is_tao_hm,
    src.is_cai_dat_hm AS is_cai_dat_hm,
    src.is_tao_wa AS is_tao_wa,
    src.is_gan_hm AS is_gan_hm,
    src.is_dc_hm_tc AS is_dc_hm_tc,
    src.is_go_hm_tc AS is_go_hm_tc,
    src.is_kep_lai AS is_kep_lai
FROM {{ ref('v_stg_bpm_tcstk_thong_tin_chung') }} src
WHERE src.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}
