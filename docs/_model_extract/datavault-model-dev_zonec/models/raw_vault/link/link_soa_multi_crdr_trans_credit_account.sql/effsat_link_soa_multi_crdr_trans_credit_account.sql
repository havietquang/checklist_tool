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
skip_matched_step   : true = bo record khong doi -> tang performance
alias               : Ten bang/view vat ly trong database. Giup giu on dinh ten output
tags                : ['<ten_nguon>'] = filter khi run (dbt run --select tag:<ten_nguon>)
================================================================================
*/
{{ config(
    alias = 'effsat_link_soa_multi_crdr_trans_credit_account',
    materialized = 'incremental_checkpoint',
    unique_key = ['link_soa_multi_crdr_trans_credit_account_hashkey', 'source_event_date'],
    incremental_strategy = 'merge',
    skip_matched_step = true,
    tags = ['ocbchannel', 'soa_multi_crdr_trans', 'zonec']
) }}

{% set source_name = 'ocbchannel' %}
{% set source_table = 'soa_multi_crdr_trans' %}
{% set link_model = 'link_soa_multi_crdr_trans_credit_account' %}
{% set unique_key = 'link_soa_multi_crdr_trans_credit_account_hashkey' %}

/*
Raw_sql tra ve tap link hashkey con hieu luc trong ngay target_date:
UNION DISTINCT 4 cot CREDIT_ACCOUNT_1..4 (nhu bang link), SELECT DISTINCT
de khu trung khi cung mot account xuat hien o nhieu slot.
*/
{%- set raw_sql -%}
SELECT DISTINCT
    {{ hash_column(['id', 'credit_account'], source_name) }} AS link_soa_multi_crdr_trans_credit_account_hashkey,
    to_date('{{ var("target_date") }}', 'yyyyMMdd') AS source_event_date,
    CONCAT(CAST('{{ source_name }}' AS string), '__', '{{ source_table }}') AS record_source,
    CAST(current_timestamp AS timestamp) AS load_timestamp
FROM (
    SELECT id, credit_account_1 AS credit_account, source_event_date
    FROM {{ ref('v_stg_ocbchannel_soa_multi_crdr_trans') }}
    UNION DISTINCT
    SELECT id, credit_account_2 AS credit_account, source_event_date
    FROM {{ ref('v_stg_ocbchannel_soa_multi_crdr_trans') }}
    UNION DISTINCT
    SELECT id, credit_account_3 AS credit_account, source_event_date
    FROM {{ ref('v_stg_ocbchannel_soa_multi_crdr_trans') }}
    UNION DISTINCT
    SELECT id, credit_account_4 AS credit_account, source_event_date
    FROM {{ ref('v_stg_ocbchannel_soa_multi_crdr_trans') }}
) t
WHERE source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
  AND id IS NOT NULL
  AND credit_account IS NOT NULL
  AND credit_account <> ''
  AND credit_account NOT LIKE 'PL%'
{%- endset %}

{{ effsat(
    unique_key = unique_key,
    link_model = link_model,
    raw_sql = raw_sql
) }}
