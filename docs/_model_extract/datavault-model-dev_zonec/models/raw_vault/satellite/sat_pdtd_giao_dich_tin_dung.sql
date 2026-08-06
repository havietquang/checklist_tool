{{ config(
    alias = 'sat_pdtd_giao_dich_tin_dung',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'append',
    unique_key = ['pdtd_nhom_giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'pdtd_giao_dich_tin_dung' %}
{% set hub_hashkey = 'pdtd_nhom_giao_dich_hashkey' %}
{% set raw_sql -%}
SELECT
    pdtd.hashkey AS {{ hub_hashkey }},
    src.hashdiff_pdtd_giao_dich_tin_dung AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    src.ma_key AS ma_key,
    src.so_tien_vay_de_xuat AS so_tien_vay_de_xuat,
    src.tong_hmrr_100 AS tong_hmrr_100,
    src.tong_hmrr_ko_100 AS tong_hmrr_ko_100,
    src.tong_dthu_gan_nhat AS tong_dthu_gan_nhat,
    src.tong_tsan_gan_nhat AS tong_tsan_gan_nhat,
    src.du_no_vay_tctd AS du_no_vay_tctd,
    src.ttin_tien_gui AS ttin_tien_gui,
    src.tvay_la_tgui AS tvay_la_tgui,
    src.loai_tsdb AS loai_tsdb,
    src.phan_loai_tsdb AS phan_loai_tsdb,
    src.ty_le_dam_bao AS ty_le_dam_bao,
    src.qche_chovay_bao_khac AS qche_chovay_bao_khac,
    src.qdinh_tin_dung AS qdinh_tin_dung,
    src.cstindung_theokh AS cstindung_theokh,
    src.spham_tindung AS spham_tindung,
    src.tyle_baodam_ngoaile AS tyle_baodam_ngoaile,
    src.ngoai_le_cv_nv_ocb AS ngoai_le_cv_nv_ocb,
    src.pdnl_upload AS pdnl_upload,
    src.ds_xe_mua_khanga AS ds_xe_mua_khanga,
    src.dsdv_banxe_ocb_cnhan AS dsdv_banxe_ocb_cnhan,
    src.tsbd AS tsbd,
    src.csh_tsbd AS csh_tsbd,
    src.ploai_bds AS ploai_bds,
    src.dvkd_tpho_trung_uong AS dvkd_tpho_trung_uong,
    src.tle_cvay_dgia_tsbd AS tle_cvay_dgia_tsbd,
    src.loai_bdsmua AS loai_bdsmua,
    src.loaikh AS loaikh,
    src.kh_nocic_12thang AS kh_nocic_12thang,
    src.diaban_dvkd AS diaban_dvkd,
    src.vitritsbd_khanga AS vitritsbd_khanga,
    src.mien_bcao_gsat_tdung AS mien_bcao_gsat_tdung,
    src.tdiem_bcao_gsat_tdung AS tdiem_bcao_gsat_tdung,
    src.ngung_qhtd_ocb_nho_6thang AS ngung_qhtd_ocb_nho_6thang,
    src.ngung_qhtd_ocb_nho_3thang AS ngung_qhtd_ocb_nho_3thang,
    src.no_qua_han AS no_qua_han,
    src.kqua_bcao_gstd AS kqua_bcao_gstd,
    src.tdiem_bcao_gstd_3t AS tdiem_bcao_gstd_3t,
    src.tong_hmuc_rui_ro AS tong_hmuc_rui_ro,
    src.loai_tdung_da_cap AS loai_tdung_da_cap,
    src.tsbd_hang_hoa AS tsbd_hang_hoa,
    src.tdiem_cap_tdung_hon_3thang AS tdiem_cap_tdung_hon_3thang,
    src.kh_mien_tdinh_ttiep AS kh_mien_tdinh_ttiep,
    src.filedinhkem AS filedinhkem,
    src.ngay_tdtt_truocday AS ngay_tdtt_truocday,
    src.no_nhom2_12thang AS no_nhom2_12thang,
    src.tthu_dk_pduyet AS tthu_dk_pduyet,
    src.datadate AS datadate,
    src.json_tin_dung_cap_moi AS json_tin_dung_cap_moi,
    src.json_tai_cap AS json_tai_cap,
    src.tai_san_dam_bao AS tai_san_dam_bao,
    src.to_trinh_goc_id AS to_trinh_goc_id,
    src.loai_hinh_vay AS loai_hinh_vay,
    src.nhom_giao_dich AS nhom_giao_dich,
    src.loai_giao_dich AS loai_giao_dich,
    src.so_tien_da_cap AS so_tien_da_cap
FROM {{ ref('v_stg_bpm_pdtd_giao_dich_tin_dung') }} src
JOIN {{ ref('v_stg_bpm_pdtd_nhom_giao_dich') }} pdtd
    ON src.nhom_giao_dich = pdtd.id
WHERE src.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql,
    list_cols=['ma_key']
) }}
