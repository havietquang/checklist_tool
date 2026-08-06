/*
================================================================================
DBT CONFIGURATION GUIDE
================================================================================
materialized        : 'incremental' = load record moi/thay doi 
                    : 'table' = full load 
                    : 'view' = chi tao view
incremental_strategy: 'merge' = upsert theo unique_key
                    : 'append' = chi insert 
                    : 'insert_overwrite' = overwrite theo partition
unique_key          : Khoa dinh danh record 
skip_matched_step   : true = bo record khong doi → tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<ten_nguon>'] = filter khi run (dbt run --select tag:<ten_nguon>)
================================================================================
*/
{{ config(
    alias = 'link_khach_hang_nhan_vien',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_khach_hang_nhan_vien_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'phase1', 'all']
) }}
-- Extraction
/*
================================================================================
LINK MACRO PARAMETERS
================================================================================
  - raw_sql : Cau SELECT tu custom de truyen truc tiep vao hub macro.
  - raw_sql phai tra ve day du cac cot:
      + source_model       : model/view staging chua du lieu nguon (ten ref duoc dung trong FROM).
      + source_name        : namespace nguon (dung de tao record_source prefix).
      + source_table       : ten bang nguon cu the (dung de tao gia tri record_source).
      + unique_key         : ten cot hash key cua Link target.
      + source_business_key_cols: cot xac dinh duy nhat cung cap cho link hash.
      + foreign_business_key_cols: map hub_hashkey -> cot nguon.

================================================================================
*/

{% set source_model = 'v_stg_bpm_khach_hang' %}
{% set source_name = 'bpm' %}
{% set source_table = 'khach_hang' %}
{% set unique_key = 'link_khach_hang_nhan_vien_hashkey' %}

/* 
Truong hop khong su dung marco link, co the su dung raw_sql nhu ben duoi de 
viet SQL thu cong, sau do truyen vao macro link de tao link
*/
{% set raw_sql %}
SELECT
    {{ hash_column(['kh.id', 'nv.ten_dang_nhap'], source_name) }} AS {{ unique_key }},
    kh.hashkey AS khach_hang_hashkey,
    nv.hashkey AS auth_nhan_vien_hashkey,
    kh.source_event_date,
    CONCAT('{{ source_name }}', '__', '{{ source_table }}') AS record_source,
    current_timestamp AS load_timestamp
FROM {{ ref(source_model) }} kh
LEFT JOIN {{ ref('v_stg_bpm_auth_nhan_vien') }} nv
    ON kh.nhan_vien_tao = nv.id
WHERE kh.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND kh.id IS NOT NULL
AND nv.ten_dang_nhap IS NOT NULL
{% endset %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    raw_sql = raw_sql
) }}

