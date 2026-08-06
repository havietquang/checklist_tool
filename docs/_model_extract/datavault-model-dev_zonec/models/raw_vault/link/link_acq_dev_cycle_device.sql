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
    alias = 'link_acq_dev_cycle_device',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_acq_dev_cycle_device_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'device', 'phase1', 'all']
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
{% set source_name = 'way4' %}
{% set source_table = 'ows_acq_dev_cycle' %}
{% set source_business_key_cols = ['a.id', 'a.device_rec__oid'] %}
{% set acq_dev_cycle_business_key_cols = ['a.id'] %}
{% set device_business_key_cols = ['a.device_rec__oid'] %}

/* 
Truong hop khong su dung marco link, co the su dung raw_sql nhu ben duoi de 
viet SQL thu cong, sau do truyen vao macro link de tao link
*/
{%- set raw_sql -%}
SELECT
    {{ hash_column(source_business_key_cols,source_name) }} AS link_acq_dev_cycle_device_hashkey,
    {{ hash_column(acq_dev_cycle_business_key_cols,source_name) }} AS acq_dev_cycle_hashkey,
    {{ hash_column(device_business_key_cols,source_name) }} AS device_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM {{ ref('v_stg_way4_acq_dev_cycle') }} a
    LEFT JOIN {{ ref('v_stg_way4_device_rec') }} d
    ON a.device_rec__oid = d.id 
    WHERE a.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
    AND a.id IS NOT NULL
    AND d.AMND_STATE = 'A'
    AND a.device_rec__oid IS NOT NULL
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}

