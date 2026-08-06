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
tags                : ['way4'] = filter khi run (dbt run --select tag:way4)
====================================================================
*/
{{ config(
    alias = 'hub_client',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['client_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'entity', 'phase1', 'all']
) }}

{% set source_name = 'way4' %}
{% set source_table = 'client' %}
{% set business_key = 'id' %}

/*
========================================================================
HUB MACRO PARAMETERS
========================================================================
  - raw_sql : Cau SELECT tu custom de truyen truc tiep vao hub macro.
  - raw_sql phai tra ve day du cac cot:
      + client_hashkey : Hash Key cua Hub.
      + business_key : Business Key cua Hub.
      + source_event_date : Ngay su kien nguon.
      + record_source : Nguon du lieu theo chuan metadata.
      + load_timestamp : Thoi diem nap du lieu.
========================================================================
*/
{% set raw_sql -%}
    SELECT
        hashkey AS client_hashkey,
        id as business_key,
        source_event_date,
        CONCAT(CAST('way4' AS string), '__', 'client') AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM {{ ref('v_stg_way4_client') }}
    WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
    AND AMND_STATE = 'A'
{%- endset %}

-- Su dung hub macro voi cau lenh raw_sql tuy chinh
{{ hub(raw_sql = raw_sql, source_name = source_name, source_table = source_table, business_key = business_key) }}





