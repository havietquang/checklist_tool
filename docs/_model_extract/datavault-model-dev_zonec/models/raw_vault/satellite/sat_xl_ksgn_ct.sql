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
    alias = 'sat_xl_ksgn_ct',
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
{% set source_table = 'xl_ksgn_ct' %}
{% set hashdiff_col = 'hashdiff_xl_ksgn_ct' %}
{% set hub_hashkey = 'xl_ksgn_chung_hashkey' %}
{% set raw_sql -%}

SELECT
    c.hashkey AS {{ hub_hashkey }},
    ct.{{ hashdiff_col }} AS hashdiff,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CAST(CURRENT_TIMESTAMP AS timestamp) AS load_timestamp,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    ct.ma_key AS ma_key,
    ct.gd_chitiet_id AS gd_chitiet_id,
    ct.giaodich_loai AS giaodich_loai,
    ct.ngay_tao AS ngay_tao,
    ct.nguoi_tao AS nguoi_tao, 
    ct.nhom_nghiepvu AS nhom_nghiepvu,
    ct.nghiepvu_ct AS nghiepvu_ct,
    ct.so_tien_gd AS so_tien_gd,
    ct.ghi_chu AS ghi_chu,
    ct.so_luong AS so_luong,
    ct.gtri_giaodich AS gtri_giaodich,
    ct.gtri_giaodich_dong AS gtri_giaodich_dong
FROM {{ ref('v_stg_bpm_xl_ksgn_ct') }} ct
INNER JOIN {{ ref('v_stg_bpm_xl_ksgn_chung') }} c
    ON ct.gd_chinh_id = c.gd_chinh_id
WHERE ct.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
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

