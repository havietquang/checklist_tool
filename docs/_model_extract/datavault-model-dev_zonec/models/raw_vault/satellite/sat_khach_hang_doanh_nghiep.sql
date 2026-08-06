{{ config(
    alias = 'sat_khach_hang_doanh_nghiep',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['khach_hang_hashkey', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase2', 'all']
) }}

{% set source_name = 'bpm' %}
{% set source_table = 'khach_hang_doanh_nghiep' %}
{% set hub_hashkey = 'khach_hang_hashkey' %}
{% set raw_sql -%}
SELECT
    src.hashkey AS {{ hub_hashkey }},
    src.hashdiff_khach_hang_doanh_nghiep AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    src.id AS id,
    src.ma_dang_ky_kinh_doanh AS ma_dang_ky_kinh_doanh,
    src.ngay_cap AS ngay_cap,
    src.noi_cap AS noi_cap,
    src.thoi_han_hoat_dong AS thoi_han_hoat_dong,
    src.giay_phep_nganh_nghe AS giay_phep_nganh_nghe,
    src.ma_giay_phep_nganh_nghe AS ma_giay_phep_nganh_nghe,
    src.noi_cap_giay_phep_nganh_nghe AS noi_cap_giay_phep_nganh_nghe,
    src.ngay_cap_giay_phep_nganh_nghe AS ngay_cap_giay_phep_nganh_nghe,
    src.hluc_giay_phep_nganh_nghe AS hluc_giay_phep_nganh_nghe,
    src.ngay_hoat_dong AS ngay_hoat_dong,
    src.nganh_dang_ky_chinh AS nganh_dang_ky_chinh,
    src.von_dieu_le AS von_dieu_le,
    src.nguoi_dai_dien_phap_luat AS nguoi_dai_dien_phap_luat,
    src.chuc_vu_nguoi_dd AS chuc_vu_nguoi_dd,
    src.so_nhan_vien_van_phong AS so_nhan_vien_van_phong,
    src.so_nhan_vien_cong_xuong AS so_nhan_vien_cong_xuong,
    src.ngay_tao AS ngay_tao,
    src.trang_thai AS trang_thai,
    src.doanh_thu_nam_gan_nhat AS doanh_thu_nam_gan_nhat,
    src.tong_tai_san_nam_gan_nhat AS tong_tai_san_nam_gan_nhat,
    src.tong_du_no_tctd AS tong_du_no_tctd,
    src.phan_khuc_khach_hang_id AS phan_khuc_khach_hang_id,
    src.ngay_thanh_lap AS ngay_thanh_lap,
    src.dia_chi_dkkd AS dia_chi_dkkd,
    src.nganh_nghe_dky_id AS nganh_nghe_dky_id,
    src.giay_chung_nhan_dau_tu AS giay_chung_nhan_dau_tu,
    src.doanh_thu_nhom_kh_lien_quan AS doanh_thu_nhom_kh_lien_quan,
    src.han_muc_rrtd_cua_kh AS han_muc_rrtd_cua_kh,
    src.dn_co_phat_trien_da_dac_thu AS dn_co_phat_trien_da_dac_thu
FROM {{ ref('v_stg_bpm_khach_hang_doanh_nghiep') }} src
WHERE src.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}
