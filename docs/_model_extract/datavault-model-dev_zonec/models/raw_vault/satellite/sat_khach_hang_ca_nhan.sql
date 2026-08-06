{{ config(
    alias = 'sat_khach_hang_ca_nhan',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['khach_hang_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'khach_hang_ca_nhan' %}
{% set hub_hashkey = 'khach_hang_hashkey' %}
{% set raw_sql -%}
SELECT
    src.hashkey AS {{ hub_hashkey }},
    src.hashdiff_khach_hang_ca_nhan AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    src.id AS id,
    src.ngay_sinh AS ngay_sinh,
    src.cmnd AS cmnd,
    src.noi_cap_cmnd AS noi_cap_cmnd,
    src.ngay_cap_cmnd AS ngay_cap_cmnd,
    src.ho_khau_thuong_tru AS ho_khau_thuong_tru,
    src.noi_o_hien_tai AS noi_o_hien_tai,
    src.so_dien_thoai AS so_dien_thoai,
    src.email AS email,
    src.ngay_tao AS ngay_tao,
    src.trang_thai AS trang_thai,
    src.tinh_trang_hnhan_id AS tinh_trang_hnhan_id,
    src.tinh_trang_hnhan AS tinh_trang_hnhan,
    src.ho_chieu AS ho_chieu,
    src.can_cuoc_cong_dan AS can_cuoc_cong_dan,
    src.gioi_tinh AS gioi_tinh,
    src.visa AS visa,
    src.ngay_cap_visa AS ngay_cap_visa,
    src.ngay_het_han_visa AS ngay_het_han_visa,
    src.ngay_hieu_luc_visa AS ngay_hieu_luc_visa,
    src.noi_cap_visa AS noi_cap_visa,
    src.thoi_han_cu_tru_vn AS thoi_han_cu_tru_vn,
    src.ngay_het_han_cmnd AS ngay_het_han_cmnd,
    src.thu_nhap_hang_thang AS thu_nhap_hang_thang,
    src.tham_nien_lam_viec AS tham_nien_lam_viec,
    src.the_can_cuoc AS the_can_cuoc,
    src.quoc_tich AS quoc_tich
FROM {{ ref('v_stg_bpm_khach_hang_ca_nhan') }} src
WHERE src.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}
