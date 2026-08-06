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
    alias = 'hub_acc_templ',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['acc_templ_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'accounting', 'phase2', 'all']
) }}

{% set source_model = 'v_stg_way4_acc_templ' %}
{% set source_name = 'way4' %}
{% set source_table = 'ows_acc_templ' %}
{% set unique_key = 'acc_templ_hashkey' %}
{% set business_key = 'id' %}
{% set raw_sql %}
SELECT
    hashkey AS acc_templ_hashkey,
    id AS business_key,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT('way4', '__', 'acc_templ') AS record_source,
    CURRENT_TIMESTAMP AS load_timestamp
FROM {{ ref('v_stg_way4_acc_templ') }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND amnd_state = 'A'
{% endset %}


/*
========================================================================
HUB MACRO PARAMETERS
========================================================================
  - source_model : Ten cua model/view nguon. VD: 'v_stg_t24_t24_ac_locked_events'.
  - source_name  : Ten he thong nguon (Record Source).
  - source_table : Ten bang nguon business duoc dua vao metadata.
  - unique_key   : Ten cot Hash Key cua Hub (Primary Key cua bang Hub).
  - business_key : Ten cot Business Key tu nguon.
========================================================================
*/

{{ hub(raw_sql=raw_sql) }}
