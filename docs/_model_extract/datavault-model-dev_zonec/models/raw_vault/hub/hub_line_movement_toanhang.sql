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
    alias = 'hub_line_movement_toanhang',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['line_movement_toanhang_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'accounting', 'phase1', 'all']
) }}

{% set source_name = 't24' %}
{% set source_table = 't24_line_mvmt_toanhang' %}
/*
========================================================================
HUB MACRO PARAMETERS
========================================================================
  - raw_sql : Cau SELECT tu custom de truyen truc tiep vao hub macro.
  - raw_sql phai tra ve day du cac cot:
      + line_movement_toanhang_hashkey : Hash key cua hub.
      + t_line_id                      : Business key nguon.
      + t_stt                          : So thu tu nguon.
      + source_event_date              : Ngay su kien.
      + record_source                  : Nguon goc ban ghi.
      + load_timestamp                 : Thoi diem nap du lieu.
========================================================================
*/

{% set raw_sql -%}
    SELECT 
        hashkey AS line_movement_toanhang_hashkey,
        t_line_id,
        t_stt,
        source_event_date,
        CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM {{ ref('v_stg_t24_t24_line_mvmt_toanhang') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

-- Su dung hub macro voi cau lenh raw_sql tuy chinh
{{ hub(raw_sql = raw_sql, source_name = source_name, source_table = source_table) }}

