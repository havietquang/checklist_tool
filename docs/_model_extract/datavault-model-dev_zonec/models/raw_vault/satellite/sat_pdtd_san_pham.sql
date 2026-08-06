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
    alias = 'sat_pdtd_san_pham',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['pdtd_nhom_giao_dich_hashkey', 'ma_key', 'hashdiff', 'source_event_date'],
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
{% set source_table = 'pdtd_san_pham' %}
{% set hashdiff_col = 'hashdiff_pdtd_san_pham' %}
{% set hub_hashkey = 'pdtd_nhom_giao_dich_hashkey' %}
{% set raw_sql -%}

SELECT
    ngd.hashkey AS {{ hub_hashkey }},
    sp.{{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    sp.ma_key AS ma_key,
    sp.rowid AS rowid,
    sp.datadate AS datadate,
    sp.gd_chinh_id AS gd_chinh_id,
    sp.muc_dich_id AS muc_dich_id,
    sp.nhom_san_pham_id AS nhom_san_pham_id,
    sp.san_pham_id AS san_pham_id,
    sp.loai_san_pham AS loai_san_pham,
    sp.so_tien_de_xuat AS so_tien_de_xuat,
    sp.so_tien_phe_duyet AS so_tien_phe_duyet,
    sp.ngay_tao AS ngay_tao,
    sp.rrtd_co_tsbd_sp_cuthe AS rrtd_co_tsbd_sp_cuthe,
    sp.rrtd_ko_tsbd_sp_cuthe AS rrtd_ko_tsbd_sp_cuthe,
    sp.rrtd_co_tsbd_sp_cuthe_pd AS rrtd_co_tsbd_sp_cuthe_pd,
    sp.rrtd_ko_tsbd_sp_cuthe_pd AS rrtd_ko_tsbd_sp_cuthe_pd,
    sp.du_no_hien_tai AS du_no_hien_tai,
    sp.rrtd_da_phe_duyet AS rrtd_da_phe_duyet,
    sp.ngay_het_han_hieu_luc_hm AS ngay_het_han_hieu_luc_hm,
    sp.ngay_lap_tt_ph_ckctd AS ngay_lap_tt_ph_ckctd,
    sp.ngay_du_kien_ph_ckctd AS ngay_du_kien_ph_ckctd
FROM {{ ref('v_stg_bpm_pdtd_san_pham') }} sp
INNER JOIN {{ ref('v_stg_bpm_pdtd_nhom_giao_dich') }} ngd
    ON sp.gd_chinh_id = ngd.id
WHERE sp.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
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

