{{ config(
    alias = 't_link_tsbd_giaodich_taisan_chusohuu',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['t_link_tsbd_giaodich_taisan_chusohuu_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'tsbd_giaodich_taisan_chusohuu' %}
{% set unique_key = 't_link_tsbd_giaodich_taisan_chusohuu_hashkey' %}

{% set raw_sql -%}
SELECT
    src.hashkey AS {{ unique_key }},
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    {{ hash_column(['src.ma_giao_dich'], source_name) }} AS tsbd_giaodich_chinh_hashkey,
    {{ hash_column(['src.ma_tai_san'], source_name) }} AS tsbd_tai_san_hashkey,
    {{ hash_column(['src.csh_id'], source_name) }} AS tsbd_chu_so_huu_hashkey,
    src.giaodich_id AS giaodich_id,
    src.taisan_id AS taisan_id,
    src.ten_tai_san AS ten_tai_san,
    src.taisan_tinh_tp_id AS taisan_tinh_tp_id,
    src.taisan_quan_huyen_id AS taisan_quan_huyen_id,
    src.bds_can_cu_dg AS bds_can_cu_dg,
    src.bds_ma_can_ho AS bds_ma_can_ho,
    src.bds_ngay_cap_cn AS bds_ngay_cap_cn,
    src.so_giay_cn AS so_giay_cn,
    src.giayto_to_chuc AS giayto_to_chuc,
    src.giayto_menh_gia AS giayto_menh_gia,
    src.giayto_ky_han AS giayto_ky_han,
    src.quyenphatsinh_ten AS quyenphatsinh_ten,
    src.quyenphatsinh_sohopdong AS quyenphatsinh_sohopdong,
    src.vongop_mack AS vongop_mack,
    src.vongop_tochucnhan AS vongop_tochucnhan,
    src.ptvt_loaiphuongtien_id AS ptvt_loaiphuongtien_id,
    src.ptvt_hangxs AS ptvt_hangxs,
    src.ptvt_bienks AS ptvt_bienks,
    src.ptvt_congnang AS ptvt_congnang,
    src.ptvt_tentau AS ptvt_tentau,
    src.ptvt_sodky AS ptvt_sodky,
    src.ptvt_taitrong AS ptvt_taitrong,
    src.hanghoa_tenquycach AS hanghoa_tenquycach,
    src.tskhac_tt_taisan AS tskhac_tt_taisan,
    src.tskhac_ghichu AS tskhac_ghichu,
    src.taisan_mo_ta AS taisan_mo_ta,
    src.taisan_dia_chi AS taisan_dia_chi,
    src.nhom_tai_san_id AS nhom_tai_san_id,
    src.loai_tai_san_id AS loai_tai_san_id,
    src.ctiet_tai_san_id AS ctiet_tai_san_id,
    src.csh_ho_ten AS csh_ho_ten,
    src.csh_cmnd AS csh_cmnd,
    src.csh_ngay_sinh AS csh_ngay_sinh,
    src.trang_thai AS trang_thai,
    src.nguoi_tao AS nguoi_tao,
    src.ngay_tao AS ngay_tao,
    src.dong_xe AS dong_xe
FROM {{ ref('v_stg_bpm_tsbd_giaodich_taisan_chusohuu') }} src
WHERE src.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ link(
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    raw_sql = raw_sql
) }}
