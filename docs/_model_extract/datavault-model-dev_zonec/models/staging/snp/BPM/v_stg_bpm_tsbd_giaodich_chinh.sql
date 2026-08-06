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
    alias = 'v_stg_bpm_tsbd_giaodich_chinh',
    materialized = 'view',
    tags = ['bpm', 'phase1', 'zonec', 'all']
) }}

/*
========================================================================
STAGE MACRO PARAMETERS
========================================================================
  - source_name           : Ten he thong nguon ('bpm'), dung de tao
                            gia tri cho cot `record_source` o downstream.
  - source_table          : Ten bang nghiep vu nguon ('tsbd_giaodich_chinh'),
                            dung de map dung snapshot/source table.
  - business_key_cols     : Danh sach cot tao thanh Business Key duy nhat
                            cua entity. ['ma_giao_dich']
                            Macro se hash cac cot nay thanh hashkey.
  - source_event_date_col : Cot ngay su kien tu nguon ('DATADATE'),
                            dung lam `source_event_date` o downstream.
  - hashdiff_satellite_dict: Dictionary anh xa ten hashdiff -> danh sach
                            cot tuong ung. Moi entry sinh ra mot cot
                            hashdiff rieng, phuc vu mot Satellite rieng
                            biet o tang raw_vault.
========================================================================
*/

{% set source_name = "bpm" -%}
{% set source_table = "tsbd_giaodich_chinh" -%}
{% set business_key_cols = ['ma_giao_dich'] -%}
{% set staging_config = get_staging_config(source_name, source_table) -%}
{% set source_event_date_col = staging_config.source_event_date_col -%}
{% set source_event_date_dttype = staging_config.source_event_date_dttype -%}
{% set hashdiff_satellite_dict =
{
   "hashdiff_tsbd_giaodich_chinh_thong_tin_chung" : ['kh_han_che', 'loai_giao_dich', 'muc_dich_vay', 'ngay_tao', 'gd_pdtd_tham_chieu_id', 'ma_gd_pdtd_tham_chieu', 'tai_san_id', 'nguoi_tao', 'trang_thai', 'giao_dich_goc', 'trang_thai_phe_duyet', 'nhom_san_pham_id', 'deactive', 'diem_phan_cong', 'dvkd_khoi_tao', 'can_bo_phe_duyet', 'can_bo_dang_xly', 'dvkd_dang_xly', 'quy_trinh', 'ly_do_dexuat', 'process_id', 'ngay_cap_nhat', 'nguoi_cap_nhat', 'ngay_chuyen_task_cbkt', 'bspo_id', 'luong_xu_ly', 'muc_dich_tham_dinh_id', 'ngay_de_xuat_pqlts_td', 'ngay_bat_dau_pqlts_td', 'gio_bat_dau_pqlts_td', 'phut_bat_dau_pqlts_td', 'muc_dich_tham_dinh_khac_ten', 'ngay_bat_dau_pqlts_td_string', 'ngay_hoan_thanh_pqlts_td', 'nhom_kh_uu_tien', 'sdt_nguoi_hd_khao_sat', 'so_bien_ban_dinh_gia', 'tai_san_du_dk_thamdinh', 'tai_san_tdtt', 'ts_cung_db_dvkd', 'ts_moi'],
   "hashdiff_tsbd_giaodich_chinh_thong_tin_dinh_gia": ['hoan_thanh', 'id_tinh_diem_pc_ktkqdg', 'is_xn_tgks_tdtt', 'json_link_tai_lieu', 'loai_dvdg', 'dvdg_ben_3_id', 'dvdg_khac', 'dvdg_khac_ten', 'gia_tri_dg', 'ngay_hoan_tat_dg', 'don_gia_dat_dg', 'dinh_gia_moi', 'ten_nguoi_hd_khao_sat', 'yeu_cau_ben_3_dg', 'yeu_cau_cap_phe_duyet', 'don_gia_dg_id', 'y_kien_dvkd', 'y_kien_phe_duyet', 'dvdg_ben_3_de_xuat_id', 'dvdg_de_xuat_khac', 'dvdg_de_xuat_khac_ten', 'ket_qua_danh_gia', 'nguyen_tac_tinh_diem_pc', 'tong_hmrr_kh_dexuat'],
   "hashdiff_tsbd_giaodich_chinh_khoi_tao_phe_duyet" : ['yeu_cau_hoi_so', 'tdv', 'cb_pqltsdb', 'tbp_pqltsdb', 'tp_pqltsdb', 'cb_kiem_tra_kqdg', 'rm2', 'tbp_ktkqdg', 'nhom_dang_xu_ly', 'cb_baogia', 'cpd_baogia', 'cpd1_ten_dn', 'cpd2_ten_dn', 'gd_tsbd_id']
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
    PARTITION BY ma_giao_dich
    ORDER BY datadate DESC, gd_tsbd_id DESC
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
