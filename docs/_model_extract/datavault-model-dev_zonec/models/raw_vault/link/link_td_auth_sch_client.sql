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
    alias = 'link_td_auth_sch_client',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_td_auth_sch_client_hashkey'],
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase2', 'all']
) }}

-- Extraction
{% set source_model = 'v_stg_way4_td_auth_sch' %}
{% set source_name = 'way4' %}
{% set source_table = 'ows_td_auth_sch' %}
{% set unique_key = 'link_td_auth_sch_client_hashkey' %}
{% set source_business_key_cols = ['t.id', 't.client__id'] %}
{% set td_auth_sch_business_key_cols = ['t.id'] %}
{% set client_business_key_cols = ['t.client__id'] %}

{% set raw_sql %}
SELECT
    {{ hash_column(source_business_key_cols, source_name) }} AS link_td_auth_sch_client_hashkey,
    {{ hash_column(td_auth_sch_business_key_cols, source_name) }} AS td_auth_sch_hashkey,
    {{ hash_column(client_business_key_cols, source_name) }} AS client_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_way4_td_auth_sch') }} t
JOIN {{ ref('v_stg_way4_client') }} c
  ON t.client__id = c.id
 AND c.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
WHERE t.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND t.amnd_state = 'A' and c.amnd_state = 'A'
  AND t.id IS NOT NULL
  AND t.client__id IS NOT NULL
{% endset %}

-------------

--Main part
{{ link(raw_sql = raw_sql) }}

