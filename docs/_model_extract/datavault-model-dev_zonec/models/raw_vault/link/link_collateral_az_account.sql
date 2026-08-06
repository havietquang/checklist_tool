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
    alias = 'link_collateral_az_account',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_collateral_az_account_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'collateral', 'phase2', 'all']
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

{% set source_name = 't24' %}
{% set source_table = 't24_collateral' %}
{% set source_business_key_cols = ['id', 't_application_id'] %}
{% set collateral_business_key_cols = ['id'] %}
{% set account_business_key_cols = ['t_application_id'] %}

/*
Truong hop khong su dung marco link, co the su dung raw_sql nhu ben duoi de
viet SQL thu cong, sau do truyen vao macro link de tao link
*/

{%- set raw_sql -%}
SELECT
    {{ hash_column(source_business_key_cols, source_name) }} AS link_collateral_az_account_hashkey,
    {{ hash_column(collateral_business_key_cols, source_name) }} AS collateral_hashkey,
    {{ hash_column(account_business_key_cols, source_name) }} AS account_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_t24_t24_collateral') }} 
        WHERE t_application_id not like "LD%"
        AND source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
        AND id IS NOT NULL
        AND t_application_id IS NOT NULL
{%- endset %}
-------------

--Main part
{{ link(raw_sql = raw_sql) }}


