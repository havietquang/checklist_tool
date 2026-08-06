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
    alias = 'link_loans_letter_of_credit',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_loans_lc_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'loan', 'phase1', 'all']
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

{% set source_model = 'v_stg_t24_t24_loans_and_deposits' %}
{% set source_name = 't24' %}
{% set source_table = 't24_loans_and_deposits' %}
{% set unique_key = 'link_loans_lc_hashkey' %}

{% set raw_sql %}
SELECT
    {{ hash_column(['id', 't_linked_tfdr_ref'], source_name) }} AS {{ unique_key }},
    {{ hash_column(['id'], source_name) }} AS loans_hashkey,
    {{ hash_column(['t_linked_tfdr_ref'], source_name) }} AS letter_of_credit_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT('{{ source_name }}', '__', '{{ source_table }}') AS record_source,
    current_timestamp AS load_timestamp
FROM {{ ref(source_model) }}
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
AND id IS NOT NULL
AND t_linked_tfdr_ref IS NOT NULL
AND t_linked_tfdr_ref LIKE 'TF%'
AND LENGTH(t_linked_tfdr_ref) = 12
{% endset %}

{{ link(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    raw_sql = raw_sql
) }}

