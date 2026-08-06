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
    alias = 'link_teller_account1',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_teller_account1_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'transaction', 'phase1', 'all']
) }}

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
{% set source_table = 't24_teller' %}
{% set source_model = 'v_stg_t24_t24_teller' %}
{% set unique_key = 'link_teller_account1_hashkey' %}

{%- set raw_sql -%}
with hash_value as
(
    select distinct
        id,
        explode(split(t_account_1, "::")) as t_account_1,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date
    from {{ ref(source_model) }}
    where source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
)
select
    {{ hash_column(['t_account_1', 'id'], source_name) }} as link_teller_account1_hashkey,
    {{ hash_column(['id'], source_name) }} as teller_hashkey,
    {{ hash_column(['t_account_1'], source_name) }} as account_hashkey,
    source_event_date,
    concat('{{ source_name }}', '__', '{{ source_table }}') as record_source,
    current_timestamp as load_timestamp
from hash_value
where id is not null
and t_account_1 is not null
and t_account_1 not like 'PL%'
{%- endset %}

{{ link(
    raw_sql = raw_sql
) }}


