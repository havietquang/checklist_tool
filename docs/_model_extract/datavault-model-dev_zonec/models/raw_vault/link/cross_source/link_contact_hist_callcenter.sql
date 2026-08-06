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
tags                : cross-source link, chi run sau khi ca 2 nguon crm va callcenter da san sang
================================================================================
Cross-source link giua CRM va Callcenter:
  - CRM side    : doc tu staging view (crm_contact_hist la full snapshot, khong co date col o bronze)
  - Callcenter  : doc truc tiep tu bronze qua source(), filter theo calldate (bigint yyyyMMdd)
  - Join key    : dialid
================================================================================
*/
{{ config(
    alias = 'link_contact_hist_callcenter',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_contact_hist_callcenter_hashkey'],
    skip_matched_step = true,
    tags = ['crm', 'call', 'phase2', 'all']
) }}

{% set source_name = 'crm' %}
{% set source_table = 'crm_contact_hist' %}
{% set source_business_key_cols = ['crm_contact_hist.id', 'callcenter._id'] %}
{% set contact_hist_business_key_cols = ['crm_contact_hist.id'] %}
{% set call_business_key_cols = ['callcenter._id'] %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(source_business_key_cols, source_name) }}  AS link_contact_hist_callcenter_hashkey,
    {{ hash_column(contact_hist_business_key_cols, source_name) }} AS crm_contact_hist_hashkey,
    {{ hash_column(call_business_key_cols, source_name) }}    AS callcenter_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd')           AS source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp)                      AS load_timestamp
FROM {{ ref('v_stg_crm_crm_contact_hist') }} crm_contact_hist
JOIN {{ source('callcenter', 'callcenter') }} callcenter
  ON crm_contact_hist.dialid = callcenter.dialid
WHERE crm_contact_hist.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND to_date(cast(callcenter.calldate as timestamp)) = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND crm_contact_hist.id IS NOT NULL
  AND callcenter._id IS NOT NULL
{%- endset %}

{{ link(raw_sql = raw_sql) }}
