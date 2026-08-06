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
    alias = 'link_credit_card_registration_bpm',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_credit_card_registration_bpm_hashkey'],
    skip_matched_step = true,
    tags = ['omni', 'bpm', 'cc_registration', 'zonec']
) }}

/*
================================================================================
LINK MACRO PARAMETERS
================================================================================
  - raw_sql : Cau SELECT tu custom de truyen truc tiep vao hub macro.
  - raw_sql phai tra ve day du cac cot:
      + link hashkey        : hash cua cap business key 2 nguon.
      + hub hashkey moi ben : lay truc tiep tu cot `hashkey` cua tung staging
                              (dong nhat voi hub_credit_card_registration va
                              hub_giao_dich vi 2 hub nay deu dung thang cot
                              hashkey cua staging, khong hash lai).
      + source_event_date, record_source, load_timestamp.

Link nay noi 2 nguon khac nhau:
  - CREDIT_CARD_REGISTRATION (omni)  : CCR.ID
  - TTD_GIAO_DICH_IGEN       (bpm)   : TTD.GD_ID
Dieu kien noi theo mapping: UPPER(CCR.REFERENCE_ID) = TTD.REFNEWFO
================================================================================
*/

{% set source_name = 'omni' %}
{% set source_table = 'credit_card_registration' %}

{%- set raw_sql -%}
SELECT
    {{ hash_column(['ccr.id', 'ttd.gd_id'], source_name) }} AS link_credit_card_registration_bpm_hashkey,
    ccr.hashkey AS credit_card_registration_hashkey,
    ttd.hashkey AS giao_dich_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM {{ ref('v_stg_omni_credit_card_registration') }} ccr
JOIN {{ ref('v_stg_bpm_ttd_giao_dich_igen') }} ttd
    ON UPPER(ccr.reference_id) = ttd.refnewfo
WHERE ccr.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND ttd.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND ccr.id IS NOT NULL
  AND ttd.gd_id IS NOT NULL
{%- endset %}

{{ link(raw_sql = raw_sql) }}
