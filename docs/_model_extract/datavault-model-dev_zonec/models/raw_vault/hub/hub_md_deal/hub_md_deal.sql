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
    alias = 'hub_md_deal',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['md_deal_hashkey'],
    skip_matched_step = true,
    tags = ['t24', 'trade_finance', 'phase1', 'all', 'bv_zonec']
) }}

{% set source_name = 't24' %}
{% set unique_key = 'md_deal_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 't24_md_deal' %}
{% set source_model = 'v_stg_t24_t24_md_deal' %}

{% set raw_sql = None %}
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

-- Su dung hub macro voi cac tham so native
{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}





