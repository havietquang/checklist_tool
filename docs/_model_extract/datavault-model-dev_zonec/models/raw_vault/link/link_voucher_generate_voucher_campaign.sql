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
    alias = 'link_voucher_generate_voucher_campaign',
    materialized = 'incremental_checkpoint',
    incremental_strategy = 'merge',
    unique_key = ['link_voucher_generate_voucher_campaign_hashkey'],
    skip_matched_step = true,
    tags = ['omni', 'voucher', 'phase2', 'all']
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

{% set source_name = 'omni' %}
{% set source_table = 'voucher_generate' %}
{% set source_model = 'v_stg_omni_voucher_generate' %}
{% set unique_key = 'link_voucher_generate_voucher_campaign_hashkey' %}

/* 
Truong hop khong su dung marco link, co the su dung raw_sql nhu ben duoi de 
viet SQL thu cong, sau do truyen vao macro link de tao link
*/
{% set raw_sql -%}

SELECT
        vc.hashkey AS link_voucher_generate_voucher_campaign_hashkey,
        {{ hash_column(['vc.voucher_serial_code'], source_name) }} as voucher_generate_hashkey,
        {{ hash_column(['v.voucher_campaign_code'], source_name) }} as voucher_campaign_hashkey,
        to_date('{{ var("target_date") }}', 'yyyyMMdd') as source_event_date,
        CONCAT(CAST('omni' AS string), '__', 'voucher_campaign') AS record_source,
        CAST(current_timestamp AS timestamp) AS load_timestamp
    FROM {{ ref('v_stg_omni_voucher_generate') }} vc
    join {{ ref('v_stg_omni_voucher_campaign') }} v
        on vc.voucher_campaign_id = v.id
    WHERE vc.source_event_date = to_date('{{ var("target_date") }}', 'yyyyMMdd')
{%- endset %}

{{ link(
    source_name = source_name,
    source_table = source_table,
    unique_key = unique_key,
    raw_sql = raw_sql,
    source_business_key_cols = ['voucher_serial_code', 'voucher_campaign_code'],
    foreign_business_key_cols = {
        'voucher_generate_hashkey': ['voucher_serial_code'],
        'voucher_campaign_hashkey': ['voucher_campaign_code']
    }
) }}


