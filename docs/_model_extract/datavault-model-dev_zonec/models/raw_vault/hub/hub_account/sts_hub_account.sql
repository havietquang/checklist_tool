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
tags                : ['t24'] = filter khi run (dbt run --select tag:t24)
====================================================================
*/
-- depends_on: {{ ref('v_stg_t24_t24_account') }}
-- depends_on: {{ ref('hub_account') }}

{{ config(
    alias = 'sts_hub_account',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['account_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['t24', 'account', 'phase2', 'phase1', 'all']
) }}

/*
========================================================================
STS HUB MACRO PARAMETERS
========================================================================
  - Luu lich su CDC delete cho Hub.
  - Chi sinh ban ghi khi key ton tai o snapshot gan nhat truoc do
    nhung bien mat o snapshot target_date.
  - Cau truc output:
      + HUB_HASHKEY
      + SOURCE_EVENT_DATE
      + CDC_STATUS = 'D'
========================================================================
*/

{% set source_model = 'v_stg_t24_t24_account' %}
{% set source_name = 't24' %}
{% set source_table = 't24_account' %}
{% set unique_key = 'account_hashkey' %}
{% set source_business_key_cols = ['id'] %}
{% set hub_model = 'hub_account' %}
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

