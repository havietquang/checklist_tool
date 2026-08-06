/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized : 'view' = chi tao view, khong luu du lieu vat ly.
               Staging luon dung view de dam bao du lieu moi nhat
               tu source duoc doc truc tiep moi khi downstream
               model chay.
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags         : ['bpm'] = filter khi run (dbt run --select tag:bpm)
====================================================================
*/

{{ config(
    alias = 'v_stg_bpm_xl_ksgn_chung',
    materialized = 'view',
    tags = ['bpm', 'phase1', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('bpm'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('xl_ksgn_chung'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['ma_giao_dich']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : None = nguon khong co cot ngay su kien ro rang;
                            macro se dung ngay load thay the.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung, tach theo nhom danh gia,
                            quy trinh, ho so va don vi phe duyet.
========================================================================
*/

{% set source_name = "bpm" -%}
{% set source_table = "xl_ksgn_chung" -%}
{% set business_key_cols = ['ma_giao_dich'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict =
{
    'hashdiff_xl_ksgn_chung_can_bo_danh_gia': ['thoi_gian_nhan_task_moi_nhat', 'cbdvtd_tgian_nhan_task', 'cbtntttm_tgian_nhan_task', 'cbgdtd_tgian_nhan_task', 'cbtntttm_id', 'ket_qua_phe_duyet', 'nhom_cbxl_tntttm', 'st_cap_pd_id', 'cb_phap_che_id', 'nhom_cbxl_dvtd', 'diem_tntttm', 'diem_gdtd', 'diem_dvtd', 'nhom_khach_hang', 'xu_ly_hs', 'co_giam_tat', 'cbql_hdtd', 'dong_hdtd_cu', 'dieu_chinh_hdtd', 'can_bo_theo_gioi'],
    'hashdiff_xl_ksgn_chung_quy_trinh_trang_thai': ['quy_trinh', 'trang_thai', 'trang_thai_phe_duyet', 'gd_trangthai', 'loai_soan_thao', 'loai_cong_viec', 'ngoai_te', 'dl_toan_ven', 'chi_tiet_hop_dong', 'ma_han_muc', 'loai_han_muc', 'ma_han_muc_t24', 'cap_phe_duyet_gan_nhat', 'luong_quy_trinh', 'so_tien_quy_doi', 'so_tat_toan', 'working_account', 'cap_do_dang_xly', 'MA_GIAO_DICH'],
    'hashdiff_xl_ksgn_chung_ho_so_chung_tu': ['ky_quy', 'so_luong_md', 'so_luong_pd', 'so_luong_ld', 'sl_hs_phai_du', 'sl_hs_thuc_te', 'ref_code', 'is_phap_che', 'so_lc', 'ngay_phat_hanh_lc', 'so_tf', 'hinh_thuc_ky_quy', 'so_tien_ky_quy', 'ty_le_ky_quy', 'so_md', 'so_ld', 'ngan_hang_phat_hanh', 'su_co_he_thong'],
    'hashdiff_xl_ksgn_chung_don_vi_khoi_tao_phe_duyet': ['gd_chinh_id','pdtd_gd_id','ngay_tao','nguoi_tao','ngay_hoan_thanh','nguoi_dang_xu_ly','donvi_xuly','dvkd_id','cbdvtd_id','cbgdtd_id','ngay_dxuat_bsung_pdnl','ngay_pdnl_ho_so','ngay_dx_bsung','ho_so_xu_ly_tai','cap_phe_duyet','ksh_id','cbqhkh_id','gdk_id','gdkqlrr_id','tdv_id','ksvgdtd_id','ksvtntttm_id','tpxlgdtd_id','cbtntttm_id','bspo_id','gd_goc_id','refcode_omni','so_cap_duyet']
}
-%}

/*
------------------------------------------------------------------------
STAGE MACRO CALL
------------------------------------------------------------------------
Guard `if execute` ngan macro chay luc dbt parse/compile
(tranh loi khi chua co context thuc thi).
Macro `stage()` se sinh ra cau SELECT day du gom:
  - Tat ca cot goc tu source
  - Cot hashkey (hash cua business_key_cols)
  - Cac cot hashdiff theo hashdiff_satellite_dict
  - Cot record_source, source_event_date, load_timestamp
------------------------------------------------------------------------
*/

{% if execute -%}
{%- set columns = get_columns(source(source_name, source_table)) -%}
{%- set cols_name = [] -%}
{%- for column in columns -%}{%- do cols_name.append(column.name) -%}{%- endfor -%}

{%- set raw_sql %}
select
    --HASH KEY
    {{ hash_column(business_key_cols, source_name) }} as hashkey,

    --ALL COLUMNS FROM SOURCE TABLE
    {% for column in columns %}src.{{ column.name }},
    {% endfor %}

    --HASHDIFF FULL
    {{ hash_column(cols_name, source_name) }} as hashdiff_full,

    --HASHDIFF SATELLITES
    {% for k, v in hashdiff_satellite_dict.items() %}{{ hash_column(v, source_name) }} as {{ k }},
    {% endfor %}

    --TIME & SOURCE COLUMNS
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    '{{ source_name }}' as record_source,
    cast(current_timestamp as timestamp) as load_timestamp

from {{ source(source_name, source_table) }} src
{% if source_event_date_col is not none %}
where {{ to_yyyymmdd_str(source_event_date_col, source_event_date_dttype) }} = '{{ var("target_date") }}'
{% endif %}
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY MA_GIAO_DICH
    ORDER BY etl_time DESC
) = 1
{%- endset %}

{{ stage(
    source_table=source_table,
    business_key_cols=business_key_cols,
    hashdiff_satellite_dict=hashdiff_satellite_dict,
    source_event_date_col=source_event_date_col,
    source_event_date_dttype=source_event_date_dttype,
    source_name=source_name,
    raw_sql=raw_sql
) }}
{% endif -%}
