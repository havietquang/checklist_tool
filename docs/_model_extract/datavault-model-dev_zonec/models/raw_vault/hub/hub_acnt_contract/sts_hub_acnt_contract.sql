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
-- depends_on: {{ ref('v_stg_way4_acnt_contract') }}
-- depends_on: {{ ref('hub_acnt_contract') }}

{{ config(
    alias = 'sts_hub_acnt_contract',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['acnt_contract_hashkey', 'source_event_date', 'cdc_status'],
    skip_matched_step = true,
    tags = ['way4', 'contract', 'phase2', 'all']
) }}

/*
========================================================================
STS HUB MACRO PARAMETERS
========================================================================
  - Luu lich su CDC delete cho Hub.
  - Chi sinh ban ghi khi key ton tai o snapshot gan nhat truoc do
    nhung bien mat o snapshot target_date.
  - Cau truc output:
      + acnt_contract_hashkey
      + source_event_date
      + cdc_status
========================================================================
*/

{% set source_model = 'v_stg_way4_acnt_contract' %}
{% set source_name = 'way4' %}
{% set source_table = 'ows_acnt_contract' %}
{% set unique_key = 'acnt_contract_hashkey' %}
{% set source_business_key_cols = ['id'] %}
{% set source_filter = "amnd_state = 'A'" %}
{% set hub_model = 'hub_acnt_contract' %}
{% set source_event_date_dttype = 'yyyyMMdd' %}

{{ sts_hub(
    source_model = source_model,
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    source_business_key_cols = source_business_key_cols,
    source_filter = source_filter,
    hub_model = hub_model,
    source_event_date_dttype = source_event_date_dttype
) }}
