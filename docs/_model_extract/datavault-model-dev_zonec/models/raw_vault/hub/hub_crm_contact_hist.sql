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
tags                : ['crm'] = filter khi run (dbt run --select tag:crm)
====================================================================
*/
{{ config(
    alias = 'hub_crm_contact_hist',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['crm_contact_hist_hashkey'],
    skip_matched_step = true,
    tags = ['crm', 'contact', 'phase2', 'all']
) }}

{% set source_name = 'crm' %}
{% set unique_key = 'crm_contact_hist_hashkey' %}
{% set business_key = 'id' %}

{% set raw_sql -%}
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

SELECT
        hashkey AS crm_contact_hist_hashkey,
        id as business_key,
        source_event_date,
        CONCAT(CAST('crm' AS string), '__', 'contact_hist') AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM {{ ref('v_stg_crm_crm_contact_hist') }}
    WHERE id is not null
    AND source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

-- Su dung hub macro voi cau lenh raw_sql tuy chinh
{{ hub(raw_sql = raw_sql, source_name = source_name, business_key = business_key) }}





