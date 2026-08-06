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
    alias = 'link_soa_multi_crdr_trans_credit_account',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_soa_multi_crdr_trans_credit_account_hashkey'],
    skip_matched_step = true,
    tags = ['ocbchannel', 'soa_multi_crdr_trans', 'zonec']
) }}

/*
================================================================================
LINK MACRO PARAMETERS
================================================================================
  - raw_sql : Cau SELECT tu custom de truyen truc tiep vao hub macro.
  - raw_sql phai tra ve day du cac cot:
      + source_model       : model/view staging chua du lieu nguon (ten ref duoc dung trong FROM).
      + source_name        : namespace nguon (dung de tao record_source prefix).
      + source_table       : ten bang nguon cu the (dung de tao gia tri record_source).
      + unique_key         : ten cot hash key cua Link target.
      + source_business_key_cols: cot xac dinh duy nhat cung cap cho link hash.
      + foreign_business_key_cols: map hub_hashkey -> cot nguon.

================================================================================
*/

{% set source_name = 'ocbchannel' %}
{% set source_table = 'soa_multi_crdr_trans' %}

/*
Dung raw_sql vi link nay theo mapping phai UNION DISTINCT 4 cot
CREDIT_ACCOUNT_1..4 thanh mot cot credit_account, va loc:
NOT LIKE 'PL%' (loai tai khoan noi bo PL), IS NOT NULL, <> ''.
*/
{%- set raw_sql -%}
SELECT
    {{ hash_column(['id', 'credit_account'], source_name) }} AS link_soa_multi_crdr_trans_credit_account_hashkey,
    {{ hash_column(['id'], source_name) }} AS soa_multi_crdr_trans_hashkey,
    {{ hash_column(['credit_account'], source_name) }} AS account_hashkey,
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

{{ link(raw_sql = raw_sql) }}
