/*
====================================================================
DBT CONFIGURATION GUIDE
====================================================================
materialized        : 'incremental' = load record moi/thay doi
incremental_strategy: 'merge' = upsert theo unique_key
unique_key          : Khoa dinh danh record
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database
tags                : ['bpm'] = filter khi run (dbt run --select tag:bpm)
====================================================================
*/
{{ config(
    alias = 'hub_auth_to_chuc_don_vi',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['auth_to_chuc_don_vi_hashkey'],
    skip_matched_step = true,
    tags = ['bpm', 'phase1', 'all']
) }}

{% set source_name = 'bpm' %}
{% set unique_key = 'auth_to_chuc_don_vi_hashkey' %}
{% set business_key = 'id' %}
{% set source_table = 'auth_to_chuc_don_vi' %}
{% set source_model = 'v_stg_bpm_auth_to_chuc_don_vi' %}

/*
========================================================================
HUB MACRO PARAMETERS
========================================================================
  - source_model : Ten cua model/view nguon.
  - source_name  : Ten he thong nguon (Record Source).
  - source_table : Ten bang nguon business duoc dua vao metadata.
  - unique_key   : Ten cot Hash Key cua Hub (Primary Key cua bang Hub).
  - business_key : Ten cot Business Key tu nguon.
========================================================================
*/

{{ hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    business_key = business_key
) }}

