/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
                    : 'table' = full load
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record (thuong: hub_hashkey + hashdiff)
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['bpm'] = filter khi run (dbt run --select tag:bpm)
====================================================================
*/

{{ config(
    alias = 'sat_xl_ct_lich_su',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['xl_ksgn_chung_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
    skip_matched_step = true,
    tags = ['bpm', 'phase1', 'all']
) }}

/*
========================================================================
SATELLITE MACRO PARAMETERS
========================================================================
  - source_name         : Ten he thong nguon, dung de tao gia tri cho cot `record_source`.
  - source_table        : Ten bang nghiep vu o he thong nguon.
  - hashdiff_col        : Ten cot hashdiff da duoc tinh san o tang staging.
  - hub_hashkey         : Ten khoa hash dung de lien ket ve bang Hub/Link.
  - source_model        : Model staging lam nguon de doc du lieu.
  - list_cols           : Danh sach cac cot nghiep vu duoc luu trong Satellite.
  - raw_sql (optional)  : Cau SQL tu viet trong truong hop logic phuc tap hoac dac biet.
========================================================================
*/

{% set source_name = 'bpm' %}
{% set source_table = 'xl_ct_lich_su' %}
{% set hashdiff_col = 'hashdiff_xl_ct_lich_su' %}
{% set hub_hashkey = 'xl_ksgn_chung_hashkey' %}

{% set raw_sql -%}
SELECT
    c.hashkey AS {{ hub_hashkey }},
    ls.{{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    ls.ma_key AS ma_key,
    ls.id AS id,
    ls.trang_thai_hs AS trang_thai_hs,
    ls.ngay_tao AS ngay_tao,
    ls.nguoi_tao AS nguoi_tao,
    ls.cpd_de_xuat AS cpd_de_xuat,
    ls.ykien_chitiet AS ykien_chitiet,
    ls.lydo_dongy_id AS lydo_dongy_id,
    ls.lydo_dongy_ct AS lydo_dongy_ct,
    ls.lydo_khong_id AS lydo_khong_id,
    ls.lydo_khong_ct AS lydo_khong_ct,
    ls.task_id AS task_id,
    ls.team_id AS team_id,
    ls.trang_thai_bat_dau AS trang_thai_bat_dau,
    ls.trang_thai_ket_thuc AS trang_thai_ket_thuc,
    ls.ket_qua_xu_ly_user AS ket_qua_xu_ly_user,
    ls.ten_tac_vu AS ten_tac_vu,
    ls.thoi_diem_ket_thuc AS thoi_diem_ket_thuc,
    ls.thoi_diem_bat_dau AS thoi_diem_bat_dau,
    ls.so_lan_ycbs AS so_lan_ycbs,
    ls.role_nhan_task AS role_nhan_task,
    ls.role_chuyen_task AS role_chuyen_task,
    ls.luong AS luong,
    ls.luong_id AS luong_id,
    ls.tong_tgian_xu_ly AS tong_tgian_xu_ly
FROM {{ ref('v_stg_bpm_xl_ct_lich_su') }} ls
INNER JOIN {{ ref('v_stg_bpm_xl_ksgn_chung') }} c
    ON ls.gd_chinh_id = c.gd_chinh_id
WHERE ls.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

/* 
Truong hop khong su dung macro satellite, co the su dung raw_sql nhu ben duoi de 
viet SQL thu cong, sau do truyen vao macro satellite de tao satellite
*/
{{ satellite(
    hub_hashkey=hub_hashkey,
    source_name=source_name,
    raw_sql=raw_sql
) }}

