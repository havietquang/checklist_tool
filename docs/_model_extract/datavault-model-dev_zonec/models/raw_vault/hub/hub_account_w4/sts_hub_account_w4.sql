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
unique_key          : Khoa dinh danh record
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['way4'] = filter khi run (dbt run --select tag:way4)
====================================================================
*/
-- depends_on: {{ ref('v_stg_way4_account') }}
-- depends_on: {{ ref('hub_account_w4') }}

{{ config(
    alias = 'sts_hub_account_w4',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['account_w4_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['way4', 'accounting', 'phase2', 'all']
) }}

/*
========================================================================
STS HUB MACRO PARAMETERS
========================================================================
  - Luu lich su CDC delete cho Hub.
  - Chi sinh ban ghi khi key ton tai o snapshot gan nhat truoc do
    nhung bien mat o snapshot target_date.
  - Cau truc output:
      + account_w4_hashkey
      + source_event_date
      + cdc_status
========================================================================
*/

{% set source_model = 'v_stg_way4_account' %}
{% set source_name = 'way4' %}
{% set source_table = 'ows_account' %}
{% set unique_key = 'account_w4_hashkey' %}
{% set source_business_key_cols = ['id'] %}
{% set hub_model = 'hub_account_w4' %}
{% set source_event_date_dttype = 'yyyyMMdd' %}

{{ sts_hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = source_business_key_cols,
    hub_model = hub_model,
    source_event_date_dttype = source_event_date_dttype
) }}
