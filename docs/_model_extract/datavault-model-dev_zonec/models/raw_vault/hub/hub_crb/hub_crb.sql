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
tags                : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/
{{ config(
    alias = 'hub_crb',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['crb_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'crb', 'phase1', 'all', 'bv_zonec']
) }}

{% set source_name = 't24' %}
{% set source_table = 't24_crb' %}

/*
========================================================================
HUB MACRO PARAMETERS
========================================================================
  - raw_sql : Cau SELECT tu custom de truyen truc tiep vao hub macro.
  - raw_sql phai tra ve day du cac cot:
      + crb_hashkey : Hash Key cua Hub.
      + business_key : Business Key cua Hub.
      + source_event_date : Ngay su kien nguon.
      + record_source : Nguon du lieu theo chuan metadata.
      + load_timestamp : Thoi diem nap du lieu.
========================================================================
*/
{% set raw_sql -%}
    SELECT distinct
        hashkey AS crb_hashkey,
        tieukhoan,
        gl,
        source_event_date,
        CONCAT(CAST('t24' AS string), '__', 't24_crb') AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM {{ ref('v_stg_t24_t24_crb') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

-- Su dung hub macro voi cau lenh raw_sql tuy chinh
{{ hub(raw_sql = raw_sql, source_name = source_name, source_table = source_table) }}





