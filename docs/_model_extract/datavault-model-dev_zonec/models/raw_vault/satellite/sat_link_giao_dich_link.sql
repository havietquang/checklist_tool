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
    alias = 'sat_link_giao_dich_link',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_giao_dich_link_hashkey', 'hashdiff', 'source_event_date'],
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
{% set source_table = 'giao_dich_link' %}
{% set hashdiff_col = 'hashdiff_link_giao_dich_link' %}
{% set hub_hashkey = 'link_giao_dich_link_hashkey' %}

{% set raw_sql -%}
SELECT
    gdl.hashkey AS {{ hub_hashkey }},
    gdl.{{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    gdl.id AS id,
    gdl.quy_trinh_link AS quy_trinh_link,
    gdl.giao_dich_ngoai_bpm AS giao_dich_ngoai_bpm,
    gdl.quy_trinh_con AS quy_trinh_con,
    gdl.cap_phe_duyet AS cap_phe_duyet,
    gdl.nguoi_phe_duyet AS nguoi_phe_duyet,
    gdl.y_kien_phe_duyet AS y_kien_phe_duyet,
    gdl.so_tien AS so_tien,
    gdl.ngay_phe_duyet AS ngay_phe_duyet,
    gdl.mo_ta AS mo_ta,
    gdl.loai_giao_dich AS loai_giao_dich,
    gdl.luong_them AS luong_them
FROM {{ ref('v_stg_bpm_giao_dich_link') }} gdl
WHERE gdl.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND gdl.gd_id IS NOT NULL
  AND gdl.ma_gd_link IS NOT NULL
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

