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
tags                : ['omni'] = filter khi run (dbt run --select tag:omni)
====================================================================
*/
{{ config(
    alias = 'hub_onboarding',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['onboarding_hashkey'],
    skip_matched_step = true,
    tags = ['omni', 'onboarding_report', 'phase1', 'all']
) }}

{% set source_name = 'omni' %}
{% set unique_key = 'onboarding_hashkey' %}
{% set business_key = 'case_key' %}
{% set source_table = 'onboarding_report' %}
{% set source_model = 'v_stg_omni_onboarding_report' %}

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





