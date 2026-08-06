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
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<ten_nguon>'] = filter khi run (dbt run --select tag:<ten_nguon>)
================================================================================
*/
{{ config(
    alias = 'link_templ_approved_acc_templ',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_templ_approved_acc_templ_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'accounting', 'phase2', 'all']
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
{% set source_table = 'ows_templ_approved' %}
{% set source_business_key_cols = ['ta.id', 'ta.acc_templ__oid'] %}
{% set templ_approved_business_key_cols = ['ta.id'] %}
{% set acc_templ_business_key_cols = ['ta.acc_templ__oid'] %}

{% set raw_sql %}
SELECT
    {{ hash_column(source_business_key_cols, source_name) }} AS link_templ_approved_acc_templ_hashkey,
    {{ hash_column(templ_approved_business_key_cols, source_name) }} AS templ_approved_hashkey,
    {{ hash_column(acc_templ_business_key_cols, source_name) }} AS acc_templ_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_way4_templ_approved') }} ta
JOIN {{ ref('v_stg_way4_acc_templ') }} at
  ON ta.acc_templ__oid = at.id
 AND at.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
WHERE ta.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND at.amnd_state = 'A'
{% endset %}

{{ link(raw_sql = raw_sql) }}

